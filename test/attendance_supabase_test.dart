import 'dart:async';

import 'package:efs_work_tracker/app/features/attendance_correction/domain/repositories/correction_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/attendance_session_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/shift_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/repositories/supabase_attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_event_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/work_duration.dart';
import 'package:efs_work_tracker/app/features/history/presentation/views/history_view.dart';
import 'package:efs_work_tracker/app/features/home/presentation/views/attendance_details_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_type.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/location_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/shift_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/repositories/attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/today_attendance_card.dart';
import 'package:efs_work_tracker/core/errors/attendance_errors.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/core/services/database_services.dart';
import 'package:efs_work_tracker/core/services/storage_services.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'helpers/fake_correction_repository.dart';

// Times are UTC. Cairo is UTC+3 until Thursday 29 October 2026 (DST), so
// the 8:00–16:00 shift on Sunday 25 October is 05:00–13:00 UTC.
const userId = '11111111-1111-4111-8111-111111111111';
const recordId = '22222222-2222-4222-8222-222222222222';
final shiftStart = DateTime.utc(2026, 10, 25, 5);
final shiftEnd = DateTime.utc(2026, 10, 25, 13);
// auto_close_deadline under the default 'midnight' policy: 00:00 Monday in
// Cairo, as the database generates it.
final deadline = DateTime.utc(2026, 10, 25, 21);
final midday = DateTime.utc(2026, 10, 25, 9); // 12:00 in Cairo
final storagePath = RegExp(
  '^$userId/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
  r'\.(jpg|jpeg|png|webp)$',
);

/// `profiles` with its schedule embedded, as the repository selects it.
Map<String, dynamic> profileJson() => {
  'schedule_id': 'schedule-1',
  'work_schedules': {
    'timezone': 'Africa/Cairo',
    'grace_minutes': 15,
    // Sunday (0) to Thursday (4), like the real schedule.
    'schedule_days': [
      for (var weekday = 0; weekday <= 4; weekday++)
        {'weekday': weekday, 'starts_at': '08:00:00', 'ends_at': '16:00:00'},
    ],
  },
};

Map<String, dynamic> eventJson(String type, DateTime at, String selfie) => {
  'event_type': type,
  'occurred_at': at.toIso8601String(),
  'latitude': 30.0275,
  'longitude': 31.4913,
  'accuracy_m': 8,
  'selfie_path': selfie,
};

/// An `attendance_records` row with its embedded `attendance_events`.
Map<String, dynamic> recordJson({
  required DateTime checkIn,
  String checkInSelfie = '$userId/in.jpg',
  DateTime? checkOut,
  String? checkOutSelfie,
  bool autoClosed = false,
  int lateMinutes = 0,
}) => {
  'id': recordId,
  'work_date': '2026-10-25',
  'timezone': 'Africa/Cairo',
  'scheduled_start': shiftStart.toIso8601String(),
  'scheduled_end': shiftEnd.toIso8601String(),
  'grace_minutes': 15,
  'actual_checkin': checkIn.toIso8601String(),
  'actual_checkout': checkOut?.toIso8601String(),
  'auto_closed': autoClosed,
  'auto_closed_at': autoClosed ? deadline.toIso8601String() : null,
  'auto_close_policy': 'midnight',
  'auto_close_deadline': deadline.toIso8601String(),
  'effective_checkin': checkIn.toIso8601String(),
  'effective_checkout': checkOut?.toIso8601String(),
  'has_correction': false,
  'late_minutes': lateMinutes,
  'attendance_events': [
    eventJson('check_in', checkIn, checkInSelfie),
    if (checkOut != null)
      eventJson('check_out', checkOut, checkOutSelfie ?? '$userId/out.jpg'),
  ],
};

AttendanceEventEntity flowEvent(AttendanceType type, {String file = 'a.jpg'}) {
  return AttendanceEventEntity(
    type: type,
    time: DateTime.utc(2026, 10, 25, 5, 7),
    location: LocationEntity(
      latitude: 30.0275,
      longitude: 31.4913,
      accuracyMeters: 8,
      capturedAt: DateTime.utc(2026, 10, 25, 5, 6),
    ),
    selfiePath: '/tmp/$file',
    selfieCapturedAt: DateTime.utc(2026, 10, 25, 5, 6),
  );
}

/// The existing database as the app sees it: one employee's own rows
/// (RLS), and `check_in` / `check_out` as they are defined today.
class FakeServer implements DatabaseServices {
  Map<String, dynamic>? profile = profileJson();
  Map<String, dynamic>? record;
  List<Map<String, dynamic>>? recordsOverride;

  /// The database's clock.
  DateTime serverNow = midday;

  /// Save the next write, then lose its response.
  bool loseNextResponse = false;

  /// Fail every read with this.
  Object? readFailure;

  /// Fail reads of this table only.
  String? readFailureFor;

  final rpcCalls = <(String, Map<String, dynamic>?)>[];
  final reads = <(String, Map<String, dynamic>?)>[];

  @override
  Future<dynamic> getData({
    required String path,
    String? documentId,
    String? column,
    Map<String, dynamic>? query,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    reads.add((path, query));
    if (readFailure case final failure?) throw failure;
    if (path == readFailureFor) throw TimeoutException(path);
    switch (path) {
      case 'profiles':
        expect(documentId, userId);
        return profile;
      case 'attendance_records':
        // Always filtered by employee: an admin's RLS shows everyone.
        expect(query!['employee_id'], userId);
        if (recordsOverride case final rows?) return rows;
        final current = record;
        if (current == null) return [];
        final matches =
            (!query.containsKey('work_date') ||
                current['work_date'] == query['work_date']) &&
            (!query.containsKey('id') || current['id'] == query['id']);
        return matches ? [current] : [];
    }
    throw UnimplementedError(path);
  }

  @override
  Future<dynamic> rpc({
    required String function,
    Map<String, dynamic>? params,
  }) async {
    rpcCalls.add((function, params));
    switch (function) {
      case 'check_in':
        expect(params!.keys, isNot(contains('p_employee_id')));
        if (record != null) {
          throw const PostgrestException(
            message: 'duplicate key value violates unique constraint',
            code: '23505',
          );
        }
        record = recordJson(
          checkIn: DateTime.utc(2026, 10, 25, 5, 7),
          checkInSelfie: params['p_selfie_path'] as String,
        );
      case 'check_out':
        final current = record;
        if (current == null || current['id'] != params!['p_attendance_id']) {
          throw const PostgrestException(
            message: 'Attendance record not found',
            code: '42501',
          );
        }
        if (current['actual_checkout'] != null) {
          throw const PostgrestException(
            message: 'Checkout was already recorded',
            code: 'P0001',
          );
        }
        // The live function: at or after auto_close_deadline it only closes
        // the day automatically, and still answers with the id.
        if (current['auto_closed'] == true || !serverNow.isBefore(deadline)) {
          current['auto_closed'] = true;
          current['auto_closed_at'] = deadline.toIso8601String();
          return recordId;
        }
        // The server's clock sets the check-out time.
        record = recordJson(
          checkIn: DateTime.parse(current['actual_checkin'] as String),
          checkInSelfie:
              '${(current['attendance_events'] as List).first['selfie_path']}',
          checkOut: serverNow,
          checkOutSelfie: params['p_selfie_path'] as String,
        );
    }
    if (loseNextResponse) {
      loseNextResponse = false;
      throw TimeoutException('response lost');
    }
    return recordId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeStorage implements StorageServices {
  final uploads = <String>[];
  Object? failure;

  @override
  Future<void> uploadFile({
    required String bucket,
    required String path,
    required String localPath,
    required String contentType,
  }) async {
    if (failure case final failure?) throw failure;
    expect(bucket, 'attendance-evidence');
    uploads.add(path);
    contentTypes.add(contentType);
  }

  final contentTypes = <String>[];

  /// The type the bytes of a path without an extension would show.
  String? sniffedType;

  @override
  Future<String?> imageTypeOf(String localPath) async => sniffedType;
}

void main() {
  tz_data.initializeTimeZones();
  final cairo = tz.getLocation('Africa/Cairo');

  group('models', () {
    test('shift instants follow Cairo’s real offset, also across DST', () {
      final day = {'starts_at': '08:00:00', 'ends_at': '16:00:00'};
      final summer = ShiftModel.fromScheduleDay(
        day,
        location: cairo,
        businessDate: DateTime(2026, 10, 25),
        graceMinutes: 15,
      );
      expect(summer.startsAt, DateTime.utc(2026, 10, 25, 5));
      expect(summer.endsAt, DateTime.utc(2026, 10, 25, 13));
      expect(summer.graceMinutes, 15);

      // Daylight saving ends on Thursday 29 October 2026 at midnight.
      final winter = ShiftModel.fromScheduleDay(
        day,
        location: cairo,
        businessDate: DateTime(2026, 11, 1),
        graceMinutes: 15,
      );
      expect(winter.startsAt, DateTime.utc(2026, 11, 1, 6));
      expect(winter.endsAt, DateTime.utc(2026, 11, 1, 14));
      expect(winter.start, const Duration(hours: 8));
    });

    test('an active session', () {
      final session = AttendanceSessionModel.fromJson(
        recordJson(checkIn: DateTime.utc(2026, 10, 25, 5, 20), lateMinutes: 5),
        shift: ShiftEntity.standard,
      );
      expect(session.isActive, isTrue);
      expect(session.canCheckOut, isTrue);
      expect(session.scheduledEnd, shiftEnd);
      expect(session.lateMinutes, 5);
      expect(session.checkIn.selfiePath, '$userId/in.jpg');
      expect(session.checkIn.location!.accuracyMeters, 8);
      expect(session.closeDeadline, deadline);
      // The timer doesn't stop at 4 PM: active until the midnight deadline,
      // and not after it, even before the server's close has run.
      expect(session.isActiveAt(shiftEnd), isTrue);
      expect(
        session.isActiveAt(deadline.subtract(const Duration(minutes: 1))),
        isTrue,
      );
      expect(session.isActiveAt(deadline), isFalse);
    });

    test('a check-out after 4 PM: 8 regular hours + observed overtime', () {
      // 10:00 → 18:30 Cairo.
      final session = AttendanceSessionModel.fromJson(
        recordJson(
          checkIn: DateTime.utc(2026, 10, 25, 7),
          checkOut: DateTime.utc(2026, 10, 25, 15, 30),
        ),
        shift: ShiftEntity.standard,
      );
      expect(session.isVerified, isTrue);
      expect(session.verifiedDuration!.regular, const Duration(hours: 8));
      expect(session.verifiedDuration!.overtime, const Duration(minutes: 30));
      expect(session.earlyLeave, Duration.zero);
    });

    test('a normal early check-out', () {
      final session = AttendanceSessionModel.fromJson(
        recordJson(
          checkIn: DateTime.utc(2026, 10, 25, 5, 7),
          checkOut: DateTime.utc(2026, 10, 25, 12, 26),
        ),
        shift: ShiftEntity.standard,
      );
      expect(session.isActive, isFalse);
      expect(session.canCheckOut, isFalse);
      expect(session.isVerified, isTrue);
      expect(session.workedDuration(), const Duration(hours: 7, minutes: 19));
      // 41 minutes short of 8 regular hours.
      expect(session.earlyLeave, const Duration(minutes: 41));
      expect(session.statusAt(midday), AttendanceDayStatus.completed);
      expect(session.workDate, DateTime(2026, 10, 25));
    });

    test('closed automatically: hours unconfirmed, nothing assumed', () {
      final session = AttendanceSessionModel.fromJson(
        recordJson(checkIn: DateTime.utc(2026, 10, 25, 5), autoClosed: true),
        shift: ShiftEntity.standard,
      );
      expect(session.isAutoClosed, isTrue);
      expect(session.checkOut, isNull, reason: 'no fabricated check-out');
      expect(session.canCheckOut, isFalse);
      expect(session.isVerified, isFalse);
      expect(session.needsReview, isTrue);
      expect(session.autoClosedAt, deadline);
      // The open hours until midnight are not counted, and not 8 either.
      expect(session.verifiedDuration, isNull);
      expect(session.durationAt(deadline), isNull);
      expect(session.earlyLeave, Duration.zero);
      expect(session.statusAt(deadline), AttendanceDayStatus.needsReview);
    });

    test('an approved correction confirms the hours of a closed day', () {
      final json = recordJson(
        checkIn: DateTime.utc(2026, 10, 25, 5),
        autoClosed: true,
      );
      json['has_correction'] = true;
      json['effective_checkin'] = DateTime.utc(
        2026,
        10,
        25,
        5,
      ).toIso8601String();
      json['effective_checkout'] = DateTime.utc(
        2026,
        10,
        25,
        12,
        30,
      ).toIso8601String();
      final session = AttendanceSessionModel.fromJson(
        json,
        shift: ShiftEntity.standard,
      );
      expect(session.needsReview, isFalse);
      expect(
        session.verifiedDuration!.worked,
        const Duration(hours: 7, minutes: 30),
      );
      expect(session.statusAt(shiftEnd), AttendanceDayStatus.completed);
    });

    test('midnight passed before the server’s close: needs review', () {
      final session = AttendanceSessionModel.fromJson(
        recordJson(checkIn: shiftStart),
        shift: ShiftEntity.standard,
      );
      expect(session.statusAt(shiftEnd), AttendanceDayStatus.inProgress);
      expect(session.statusAt(deadline), AttendanceDayStatus.needsReview);
      expect(session.durationAt(deadline), isNull);
    });
  });

  group('WorkDuration', () {
    // The table from the requirements: 8 regular hours from check-in.
    final cases = <(int, int, Duration, Duration)>[
      (8 * 60, 16 * 60, const Duration(hours: 8), Duration.zero),
      (9 * 60, 17 * 60, const Duration(hours: 8), Duration.zero),
      (10 * 60, 18 * 60, const Duration(hours: 8), Duration.zero),
      (
        10 * 60,
        18 * 60 + 30,
        const Duration(hours: 8),
        const Duration(minutes: 30),
      ),
      (10 * 60, 19 * 60, const Duration(hours: 8), const Duration(hours: 1)),
    ];
    for (final (inMinutes, outMinutes, regular, overtime) in cases) {
      test('in $inMinutes → out $outMinutes', () {
        final worked = WorkDuration(Duration(minutes: outMinutes - inMinutes));
        expect(worked.regular, regular);
        expect(worked.overtime, overtime);
        expect(worked.shortfall, Duration.zero);
      });
    }

    test('short days and bad input', () {
      final short = WorkDuration(Duration(hours: 6, minutes: 15));
      expect(short.regular, const Duration(hours: 6, minutes: 15));
      expect(short.overtime, Duration.zero);
      expect(short.shortfall, const Duration(hours: 1, minutes: 45));
      // An end before the start never counts as negative time.
      expect(WorkDuration(const Duration(minutes: -5)).worked, Duration.zero);
    });

    test('an active session counts from the recorded check-in', () {
      final session = AttendanceSessionModel.fromJson(
        recordJson(checkIn: DateTime.utc(2026, 10, 25, 4)),
        shift: ShiftEntity.standard,
      );
      // 07:00 Cairo check-in, read at 15:30 Cairo: 8h 30m so far.
      final now = DateTime.utc(2026, 10, 25, 12, 30);
      expect(session.durationAt(now)!.regular, const Duration(hours: 8));
      expect(session.durationAt(now)!.overtime, const Duration(minutes: 30));
      // Recalculated from timestamps, so a restart changes nothing.
      expect(session.durationAt(now), session.durationAt(now));
    });

    test('a record without a check-in time is rejected', () {
      final json = recordJson(checkIn: DateTime.utc(2026, 10, 25, 5))
        ..['actual_checkin'] = null;
      expect(
        () =>
            AttendanceSessionModel.fromJson(json, shift: ShiftEntity.standard),
        throwsFormatException,
      );
    });
  });

  group('failureFor', () {
    AttendanceFailure map(String? code, String message) =>
        SupabaseAttendanceRepository.failureFor(code, message);

    test('maps every error the existing functions raise', () {
      expect(map('23505', 'duplicate key'), AttendanceFailure.alreadyCheckedIn);
      expect(
        map('42501', 'Attendance record not found'),
        AttendanceFailure.notCheckedIn,
      );
      expect(
        map('42501', 'An active, password-ready authorized account'),
        AttendanceFailure.accountNotReady,
      );
      expect(
        map('22023', 'Valid GPS coordinates and accuracy are required'),
        AttendanceFailure.invalidLocation,
      );
      expect(
        map('22023', 'Upload an owned selfie before submitting attendance'),
        AttendanceFailure.selfieMissing,
      );
      expect(
        map('P0001', 'There is no scheduled shift today'),
        AttendanceFailure.notWorkingDay,
      );
      expect(
        map('P0001', 'The shift has ended; check-in is closed'),
        AttendanceFailure.checkInClosed,
      );
      expect(
        map('P0001', 'The working date changed; please retry'),
        AttendanceFailure.workDateChanged,
      );
      expect(
        map('P0001', 'Checkout was already recorded'),
        AttendanceFailure.alreadyCheckedOut,
      );
      expect(
        map('P0001', 'No assigned work schedule'),
        AttendanceFailure.noSchedule,
      );
      expect(map('PGRST301', 'JWT expired'), AttendanceFailure.accountNotReady);
      expect(map('XX000', 'boom'), AttendanceFailure.unknown);
    });
  });

  group('SupabaseAttendanceRepository', () {
    late FakeServer server;
    late FakeStorage storage;
    late DateTime deviceNow;
    late SupabaseAttendanceRepository repository;

    SupabaseAttendanceRepository repositoryFor(String? user) =>
        SupabaseAttendanceRepository(
          databaseServices: server,
          storageServices: storage,
          currentUserId: () => user,
          now: () => deviceNow,
        );

    setUp(() {
      server = FakeServer();
      storage = FakeStorage();
      deviceNow = midday;
      repository = repositoryFor(userId);
    });

    int callsTo(String function) =>
        server.rpcCalls.where((call) => call.$1 == function).length;

    test('web: a blob: selfie gets its type from its bytes', () async {
      final event = flowEvent(AttendanceType.checkIn);
      final web = AttendanceEventEntity(
        type: event.type,
        time: event.time,
        location: event.location,
        selfiePath: 'blob:http://localhost:5000/0b1c2d3e',
        selfieCapturedAt: event.selfieCapturedAt,
      );
      storage.sniffedType = 'png';
      final session = await repository.checkIn(web);
      expect(storage.uploads.single, endsWith('.png'));
      expect(storage.uploads.single, matches(storagePath));
      expect(storage.contentTypes.single, 'image/png');
      expect(session.checkIn.selfiePath, storage.uploads.single);

      storage.sniffedType = null;
      server.record = null;
      await expectLater(
        repositoryFor(userId).checkIn(web),
        throwsA(AttendanceFailure.selfieUploadFailed),
      );
    });

    test('image types are read from their signatures', () {
      expect(imageTypeFromBytes(const [0xFF, 0xD8, 0xFF, 0xE0]), 'jpg');
      expect(imageTypeFromBytes(const [0x89, 0x50, 0x4E, 0x47, 0x0D]), 'png');
      expect(
        imageTypeFromBytes('RIFF\x00\x00\x00\x00WEBPVP8 '.codeUnits),
        'webp',
      );
      expect(imageTypeFromBytes('GIF89a'.codeUnits), isNull);
      expect(imageTypeFromBytes(const []), isNull);
    });

    test('today uses the work date in Cairo, not on the device', () async {
      // 22:30 UTC on Sunday is 01:30 on Monday in Cairo.
      deviceNow = DateTime.utc(2026, 10, 25, 22, 30);
      final today = await repository.getToday();

      final query = server.reads.last.$2!;
      expect(query['work_date'], '2026-10-26');
      expect(today.shift!.startsAt, DateTime.utc(2026, 10, 26, 5));
    });

    test('day off: Friday has no shift', () async {
      deviceNow = DateTime.utc(2026, 10, 30, 9);
      final today = await repository.getToday();
      expect(today.shift, isNull);
      expect(today.session, isNull);
    });

    test('a hidden or missing profile, and a missing schedule', () async {
      server.profile = null;
      await expectLater(
        repository.getToday(),
        throwsA(AttendanceFailure.accountNotReady),
      );

      server.profile = {'schedule_id': 'x', 'work_schedules': null};
      await expectLater(
        repository.getToday(),
        throwsA(AttendanceFailure.noSchedule),
      );
    });

    test(
      'malformed or impossible data is an error, not "no check-in"',
      () async {
        server.recordsOverride = [
          recordJson(checkIn: shiftStart),
          recordJson(checkIn: shiftStart),
        ];
        await expectLater(
          repository.getToday(),
          throwsA(AttendanceFailure.unknown),
        );

        server.recordsOverride = [
          recordJson(checkIn: shiftStart)..['actual_checkin'] = null,
        ];
        await expectLater(
          repository.getToday(),
          throwsA(AttendanceFailure.unknown),
        );
      },
    );

    test('no answer while reading: a network failure', () async {
      server.readFailure = TimeoutException('x');
      await expectLater(
        repository.getToday(),
        throwsA(AttendanceFailure.network),
      );
    });

    test(
      'check-in uploads the selfie to the user’s folder, then saves',
      () async {
        final session = await repository.checkIn(
          flowEvent(AttendanceType.checkIn),
        );

        expect(storage.uploads, hasLength(1));
        expect(storage.uploads.single, matches(storagePath));
        final params = server.rpcCalls.single.$2!;
        expect(params['p_selfie_path'], storage.uploads.single);
        // The result is the record read back, not the tapped event.
        expect(session.id, recordId);
        expect(session.checkIn.selfiePath, storage.uploads.single);
      },
    );

    test(
      'a lost response after the server saved is reconciled, not resent',
      () async {
        server.loseNextResponse = true;
        final session = await repository.checkIn(
          flowEvent(AttendanceType.checkIn),
        );
        expect(session.id, recordId);
        expect(callsTo('check_in'), 1);
      },
    );

    test('a retry reuses the uploaded selfie path', () async {
      storage.failure = TimeoutException('upload');
      await expectLater(
        repository.checkIn(flowEvent(AttendanceType.checkIn)),
        throwsA(AttendanceFailure.selfieUploadFailed),
      );
      storage.failure = null;
      await repository.checkIn(flowEvent(AttendanceType.checkIn));

      // Same capture again: same path, matched to the saved check-in.
      final again = await repository.checkIn(flowEvent(AttendanceType.checkIn));
      expect(again.id, recordId);
      expect(storage.uploads.toSet(), hasLength(1));
    });

    test(
      'a check-in from another phone is reported, not overwritten',
      () async {
        server.record = recordJson(checkIn: DateTime.utc(2026, 10, 25, 5));
        await expectLater(
          repository.checkIn(flowEvent(AttendanceType.checkIn)),
          throwsA(AttendanceFailure.alreadyCheckedIn),
        );
        expect(
          server.record!['actual_checkin'],
          DateTime.utc(2026, 10, 25, 5).toIso8601String(),
        );
      },
    );

    test('check-out targets the session’s record, once', () async {
      final session = await repository.checkIn(
        flowEvent(AttendanceType.checkIn),
      );
      server.serverNow = DateTime.utc(2026, 10, 25, 12, 26);
      final finished = await repository.checkOut(
        session,
        flowEvent(AttendanceType.checkOut, file: 'b.jpg'),
      );
      expect(finished.checkOutTime, DateTime.utc(2026, 10, 25, 12, 26));
      expect(server.rpcCalls.last.$2!['p_attendance_id'], recordId);

      await expectLater(
        repository.checkOut(
          finished,
          flowEvent(AttendanceType.checkOut, file: 'c.jpg'),
        ),
        throwsA(AttendanceFailure.alreadyCheckedOut),
      );
      expect(callsTo('check_out'), 1);
    });

    test(
      'a repeated check-out after a lost response returns the first one',
      () async {
        final session = await repository.checkIn(
          flowEvent(AttendanceType.checkIn),
        );
        server.loseNextResponse = true;
        final out = flowEvent(AttendanceType.checkOut, file: 'b.jpg');
        final finished = await repository.checkOut(session, out);
        expect(finished.canCheckOut, isFalse);

        // The app still had the old session and retries with the same selfie:
        // "already recorded" is matched to this check-out.
        final again = await repository.checkOut(session, out);
        expect(again.checkOutTime, finished.checkOutTime);
      },
    );

    test('a check-out from another phone is reported', () async {
      final session = await repository.checkIn(
        flowEvent(AttendanceType.checkIn),
      );
      server.record = recordJson(
        checkIn: DateTime.utc(2026, 10, 25, 5, 7),
        checkInSelfie: session.checkIn.selfiePath!,
        checkOut: DateTime.utc(2026, 10, 25, 11),
        checkOutSelfie: '$userId/other-phone.jpg',
      );
      await expectLater(
        repository.checkOut(
          session,
          flowEvent(AttendanceType.checkOut, file: 'b.jpg'),
        ),
        throwsA(AttendanceFailure.alreadyCheckedOut),
      );
    });

    test('after the midnight deadline no check-out is sent (it would save nothing)', () async {
      final session = await repository.checkIn(
        flowEvent(AttendanceType.checkIn),
      );
      deviceNow = deadline;
      await expectLater(
        repository.checkOut(
          session,
          flowEvent(AttendanceType.checkOut, file: 'b.jpg'),
        ),
        throwsA(AttendanceFailure.closedAutomatically),
      );
      expect(callsTo('check_out'), 0);
      expect(storage.uploads, hasLength(1), reason: 'no selfie uploaded');
    });

    test('a check-out at 6:30 PM is recorded with its real time', () async {
      final session = await repository.checkIn(
        flowEvent(AttendanceType.checkIn),
      );
      deviceNow = DateTime.utc(2026, 10, 25, 15, 30);
      server.serverNow = deviceNow;
      final finished = await repository.checkOut(
        session,
        flowEvent(AttendanceType.checkOut, file: 'b.jpg'),
      );
      expect(finished.checkOutTime, DateTime.utc(2026, 10, 25, 15, 30));
      expect(finished.isVerified, isTrue);
      // Checked in 08:07 Cairo, out 18:30: 8 h + 2 h 23 m observed.
      expect(
        finished.verifiedDuration!.overtime,
        const Duration(hours: 2, minutes: 23),
      );
    });

    test(
      'a check-out that meets the deadline on the server is not a success',
      () async {
        final session = await repository.checkIn(
          flowEvent(AttendanceType.checkIn),
        );
        // The phone is a little behind the database's clock.
        deviceNow = deadline.subtract(const Duration(seconds: 5));
        server.serverNow = deadline;
        await expectLater(
          repository.checkOut(
            session,
            flowEvent(AttendanceType.checkOut, file: 'b.jpg'),
          ),
          throwsA(AttendanceFailure.closedAutomatically),
        );
        expect(server.record!['actual_checkout'], isNull);
      },
    );

    test(
      'saved but not readable: the outcome is reported as unknown',
      () async {
        server.loseNextResponse = true;
        final pending = repository.checkIn(flowEvent(AttendanceType.checkIn));
        server.readFailure = TimeoutException('x');
        await expectLater(pending, throwsA(AttendanceFailure.outcomeUnknown));
      },
    );

    test('evidence is required and checked before anything is sent', () async {
      const noSelfie = AttendanceEventEntity(type: AttendanceType.checkIn);
      await expectLater(
        repository.checkIn(noSelfie),
        throwsA(AttendanceFailure.selfieMissing),
      );

      final heic = flowEvent(AttendanceType.checkIn, file: 'a.heic');
      await expectLater(
        repository.checkIn(heic),
        throwsA(AttendanceFailure.selfieUploadFailed),
      );
      expect(server.rpcCalls, isEmpty);
      expect(storage.uploads, isEmpty);
    });

    test('signed out: nothing is read or uploaded', () async {
      repository = repositoryFor(null);
      await expectLater(
        repository.getToday(),
        throwsA(AttendanceFailure.accountNotReady),
      );
      await expectLater(
        repository.checkIn(flowEvent(AttendanceType.checkIn)),
        throwsA(AttendanceFailure.accountNotReady),
      );
      expect(server.reads, isEmpty);
      expect(storage.uploads, isEmpty);
    });

    test('history is the employee’s own days, newest first', () async {
      server.record = recordJson(checkIn: shiftStart, autoClosed: true);
      final history = await repository.getHistory();

      expect(history.single.id, recordId);
      expect(history.single.needsReview, isTrue);
      // The shift comes from the record's own saved schedule.
      expect(history.single.shift.end, const Duration(hours: 16));
      final read = server.reads.last;
      expect(read.$1, 'attendance_records');
      expect(read.$2, {'employee_id': userId});
    });

    test('overtime comes from worked time, never from requests', () async {
      // 05:00–15:30 UTC: 10 h 30 m worked, so 2 h 30 m overtime.
      server.record = recordJson(
        checkIn: shiftStart,
        checkOut: DateTime.utc(2026, 10, 25, 15, 30),
      );
      final session = await repository.getSession(recordId);
      expect(
        session!.verifiedDuration!.overtime,
        const Duration(hours: 2, minutes: 30),
      );
      await repository.getToday();
      expect(
        server.reads.map((r) => r.$1),
        isNot(contains('overtime_requests')),
      );
      expect(await repository.getSession('someone-elses-id'), isNull);
    });
  });

  group('History and details pages', () {
    Future<void> showPage(
      WidgetTester tester,
      Widget page,
      _ScriptedRepository repository,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // A fresh tree, so each call gets new page cubits.
      await tester.pumpWidget(const SizedBox());
      final session = AttendanceSessionCubit(repository);
      addTearDown(session.close);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AttendanceRepository>.value(value: repository),
            RepositoryProvider<CorrectionRepository>.value(
              value: FakeCorrectionRepository(),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => ClockCubit(now: () => midday)),
              BlocProvider.value(value: session),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: page,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    AttendanceSessionEntity closedDay() => AttendanceSessionModel.fromJson(
      recordJson(checkIn: shiftStart, autoClosed: true),
      shift: ShiftEntity.standard,
    );

    AttendanceSessionEntity verifiedDay() => AttendanceSessionModel.fromJson(
      recordJson(
        checkIn: shiftStart,
        // 9 h 26 m worked: 8 h regular, 1 h 26 m overtime.
        checkOut: DateTime.utc(2026, 10, 25, 14, 26),
      ),
      shift: ShiftEntity.standard,
    );

    testWidgets('history: empty, error, and a day needing review', (
      tester,
    ) async {
      final repository = _ScriptedRepository();
      await showPage(tester, const HistoryView(), repository);
      expect(find.text('No attendance yet'), findsOneWidget);

      repository.historyFailure = TimeoutException('x');
      await showPage(tester, const HistoryView(), repository);
      expect(
        find.text('Couldn’t load your attendance history.'),
        findsOneWidget,
      );

      repository
        ..historyFailure = null
        ..history = [closedDay()];
      await showPage(tester, const HistoryView(), repository);
      expect(tester.takeException(), isNull);
      expect(find.text('Needs Review'), findsOneWidget);
      expect(find.text('Not confirmed'), findsOneWidget);
    });

    testWidgets('details of a closed day: no hours, flagged for review', (
      tester,
    ) async {
      final repository = _ScriptedRepository()..history = [closedDay()];
      await showPage(
        tester,
        const AttendanceDetailsView(id: recordId),
        repository,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Automatically closed'), findsOneWidget);
      expect(find.text('No employee checkout recorded'), findsWidgets);
      expect(find.text('Not confirmed'), findsOneWidget);
      expect(find.text('Flagged for administrative review'), findsOneWidget);
      expect(find.text('System generated'), findsOneWidget);
    });

    testWidgets('details of a checked-out day: hours and automatic overtime', (
      tester,
    ) async {
      final repository = _ScriptedRepository()..history = [verifiedDay()];
      await showPage(
        tester,
        const AttendanceDetailsView(id: recordId),
        repository,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Regular hours'), findsOneWidget);
      expect(find.text('8h 0m'), findsOneWidget, reason: 'regular hours');
      expect(find.text('Overtime'), findsOneWidget);
      expect(find.text('1h 26m'), findsOneWidget, reason: 'automatic overtime');
      expect(
        find.text(
          'Overtime: 1h 26m. Counted automatically: every minute worked '
          'beyond 8 hours.',
        ),
        findsOneWidget,
      );
      expect(find.text('Flagged for administrative review'), findsNothing);
    });

    testWidgets('details of an unknown or another employee’s day', (
      tester,
    ) async {
      await showPage(
        tester,
        const AttendanceDetailsView(id: 'missing'),
        _ScriptedRepository(),
      );
      expect(
        find.text('This attendance record was not found.'),
        findsOneWidget,
      );
    });
  });

  group('AttendanceSessionCubit', () {
    test(
      'follows the account and never shows the previous user’s day',
      () async {
        final slow = Completer<AttendanceToday>();
        final repository = _ScriptedRepository()..nextToday = slow.future;
        final cubit = AttendanceSessionCubit(repository);
        addTearDown(cubit.close);

        cubit.userChanged('user-a');
        expect(cubit.state, isA<AttendanceSessionLoading>());

        // Account changes while user A's day is still loading.
        repository.nextToday = Future.value((shift: null, session: null));
        cubit.userChanged('user-b');
        await Future<void>.delayed(Duration.zero);
        final userB = cubit.state;
        expect(userB, isA<AttendanceSessionLoaded>());

        slow.complete((shift: ShiftEntity.standard, session: null));
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state, same(userB), reason: 'user A’s late answer');

        cubit.userChanged(null);
        expect(cubit.state, isA<AttendanceSessionLoading>());
      },
    );

    test('one save at a time; a stale load can’t overwrite it', () async {
      final saving = Completer<void>();
      final repository = _ScriptedRepository()
        ..nextToday = Future.value((shift: ShiftEntity.standard, session: null))
        ..beforeCheckIn = saving.future;
      final cubit = AttendanceSessionCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();

      final first = cubit.record(flowEvent(AttendanceType.checkIn));
      await expectLater(
        cubit.record(flowEvent(AttendanceType.checkIn)),
        throwsA(AttendanceFailure.busy),
      );
      // A refresh during the save is skipped.
      await cubit.load();
      expect(repository.todayCalls, 1);

      saving.complete();
      await first;
      final state = cubit.state as AttendanceSessionLoaded;
      expect(state.session, isNotNull);
    });

    test('a conflict reloads today', () async {
      final repository = _ScriptedRepository()
        ..nextToday = Future.value((shift: ShiftEntity.standard, session: null))
        ..checkInFailure = AttendanceFailure.alreadyCheckedIn;
      final cubit = AttendanceSessionCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();

      await expectLater(
        cubit.record(flowEvent(AttendanceType.checkIn)),
        throwsA(AttendanceFailure.alreadyCheckedIn),
      );
      expect(repository.todayCalls, 2);
    });
  });

  group('Home card', () {
    Future<void> showCard(
      WidgetTester tester, {
      required AttendanceToday today,
      required DateTime now,
    }) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = AttendanceSessionCubit(
        _ScriptedRepository()..nextToday = Future.value(today),
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ClockCubit(now: () => now)),
            BlocProvider.value(value: cubit..load()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: TodayAttendanceCard()),
            ),
          ),
        ),
      );
      await tester.pump();
      addTearDown(cubit.close);
    }

    final shift = ShiftModel.fromScheduleDay(
      {'starts_at': '08:00:00', 'ends_at': '16:00:00'},
      location: cairo,
      businessDate: DateTime(2026, 10, 25),
      graceMinutes: 15,
    );

    testWidgets('day off: no check-in button', (tester) async {
      await showCard(
        tester,
        today: (shift: null, session: null),
        now: shiftStart,
      );
      expect(find.text('Check In Now'), findsNothing);
      expect(
        find.text('Today is not a working day in your schedule.'),
        findsOneWidget,
      );
    });

    testWidgets('before the shift ends: check-in offered', (tester) async {
      await showCard(
        tester,
        today: (shift: shift, session: null),
        now: shiftStart,
      );
      expect(find.text('Check In Now'), findsOneWidget);
    });

    testWidgets('after the shift ends: check-in closed', (tester) async {
      await showCard(
        tester,
        today: (shift: shift, session: null),
        now: shiftEnd,
      );
      expect(find.text('Check In Now'), findsNothing);
      expect(
        find.text('Today’s shift has ended, so check-in is closed.'),
        findsOneWidget,
      );
    });

    testWidgets('closed automatically: no check-out, overtime pointer', (
      tester,
    ) async {
      final session = AttendanceSessionModel.fromJson(
        recordJson(checkIn: shiftStart, autoClosed: true),
        shift: shift,
      );
      await showCard(
        tester,
        today: (shift: shift, session: session),
        now: deadline.add(const Duration(minutes: 5)),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Closed automatically'), findsOneWidget);
      expect(find.text('Closed at'), findsOneWidget);
      expect(find.text('Not confirmed'), findsOneWidget);
      expect(find.text('Needs Review'), findsOneWidget);
      expect(find.text('Check out'), findsNothing);
      expect(find.textContaining('send an overtime request'), findsOneWidget);
      expect(find.text('View attendance details'), findsOneWidget);
    });

    testWidgets('midnight passed before the server’s close: same card', (
      tester,
    ) async {
      final session = AttendanceSessionModel.fromJson(
        recordJson(checkIn: shiftStart),
        shift: shift,
      );
      await showCard(
        tester,
        today: (shift: shift, session: session),
        now: deadline,
      );
      expect(find.text('Closed automatically'), findsOneWidget);
      expect(find.text('Check out'), findsNothing);
    });

    testWidgets('after 4 PM the session is still running', (tester) async {
      final session = AttendanceSessionModel.fromJson(
        recordJson(checkIn: shiftStart),
        shift: shift,
      );
      await showCard(
        tester,
        today: (shift: shift, session: session),
        now: shiftEnd.add(const Duration(hours: 2)),
      );
      expect(find.text('Check out'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('8 hours at'), findsOneWidget);
    });

    testWidgets('active: check-out offered', (tester) async {
      final session = AttendanceSessionModel.fromJson(
        recordJson(checkIn: shiftStart),
        shift: shift,
      );
      await showCard(
        tester,
        today: (shift: shift, session: session),
        now: midday,
      );
      expect(find.text('Check out'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });
  });
}

/// Repository whose answers each test sets.
class _ScriptedRepository implements AttendanceRepository {
  Future<AttendanceToday> nextToday = Future.value((
    shift: null,
    session: null,
  ));
  Future<void>? beforeCheckIn;
  AttendanceFailure? checkInFailure;
  int todayCalls = 0;
  List<AttendanceSessionEntity> history = [];
  Object? historyFailure;

  @override
  Future<AttendanceToday> getToday() {
    todayCalls++;
    return nextToday;
  }

  @override
  Future<List<AttendanceSessionEntity>> getHistory({int limit = 60}) async {
    if (historyFailure case final failure?) throw failure;
    return history;
  }

  @override
  Future<AttendanceSessionEntity?> getSession(String id) async =>
      history.where((s) => s.id == id).firstOrNull;

  @override
  Future<AttendanceSessionModel> checkIn(AttendanceEventEntity event) async {
    await beforeCheckIn;
    if (checkInFailure case final failure?) throw failure;
    return AttendanceSessionModel.fromJson(
      recordJson(checkIn: event.time!),
      shift: ShiftEntity.standard,
    );
  }

  @override
  Future<AttendanceSessionModel> checkOut(session, event) =>
      throw UnimplementedError();
}
