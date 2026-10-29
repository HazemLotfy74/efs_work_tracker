import 'dart:async';

import 'package:efs_work_tracker/app/features/attendance_correction/data/models/correction_request_model.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/data/repositories/supabase_correction_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/domain/correction_rules.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/domain/entities/correction_request_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/domain/repositories/correction_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/presentation/manager/correction_form_cubit/correction_form_cubit.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/presentation/manager/pending_corrections_cubit/pending_corrections_cubit.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/presentation/views/correction_form_view.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/presentation/views/pending_corrections_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/attendance_session_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/shift_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_event_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/repositories/attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/home/presentation/views/attendance_details_view.dart';
import 'package:efs_work_tracker/app/features/profile/presentation/widgets/profile_view_body.dart';
import 'package:efs_work_tracker/core/errors/correction_errors.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/core/manager/locale_cubit.dart';
import 'package:efs_work_tracker/core/services/database_services.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/app_providers.dart';
import 'helpers/fake_admin_repository.dart';
import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_correction_repository.dart';

// Times are UTC. Cairo is UTC+3 until 29 October 2026, so Sunday
// 25 October's 8:00–16:00 shift is 05:00–13:00 UTC and its midnight
// deadline is 21:00 UTC.
const employeeId = '11111111-1111-4111-8111-111111111111';
const adminId = '33333333-3333-4333-8333-333333333333';
const recordId = '22222222-2222-4222-8222-222222222222';
final shiftStart = DateTime.utc(2026, 10, 25, 5);
final shiftEnd = DateTime.utc(2026, 10, 25, 13);
final deadline = DateTime.utc(2026, 10, 25, 21);
final nextDay = DateTime.utc(2026, 10, 26, 9);

/// An `attendance_records` row the server closed at midnight.
Map<String, dynamic> closedRecordJson({String owner = employeeId}) => {
  'id': recordId,
  'employee_id': owner,
  'work_date': '2026-10-25',
  'timezone': 'Africa/Cairo',
  'scheduled_start': shiftStart.toIso8601String(),
  'scheduled_end': shiftEnd.toIso8601String(),
  'grace_minutes': 15,
  'actual_checkin': DateTime.utc(2026, 10, 25, 5, 7).toIso8601String(),
  'actual_checkout': null,
  'auto_closed': true,
  'auto_closed_at': deadline.toIso8601String(),
  'auto_close_policy': 'midnight',
  'auto_close_deadline': deadline.toIso8601String(),
  'effective_checkin': null,
  'effective_checkout': null,
  'has_correction': false,
  'late_minutes': 0,
  'updated_at': deadline.toIso8601String(),
  'attendance_events': <Map<String, dynamic>>[],
};

AttendanceSessionEntity sessionOf(Map<String, dynamic> json) =>
    AttendanceSessionModel.fromJson(json, shift: ShiftModel.fromRecord(json));

CorrectionRequestEntity requestOf({
  String id = 'request-1',
  CorrectionStatus status = CorrectionStatus.pending,
  String? note,
}) => CorrectionRequestEntity(
  id: id,
  employeeId: employeeId,
  attendanceId: recordId,
  proposedCheckIn: DateTime.utc(2026, 10, 25, 5, 7),
  proposedCheckOut: DateTime.utc(2026, 10, 25, 13, 30),
  reason: 'Phone battery died',
  status: status,
  createdAt: nextDay,
  reviewNote: note,
  employeeName: 'Mona Ali',
  employeeCode: 'EMP-7',
  workDate: DateTime(2026, 10, 25),
  timezone: 'Africa/Cairo',
  actualCheckIn: DateTime.utc(2026, 10, 25, 5, 7),
);

/// The live `request_attendance_correction`, `review_request` and the
/// `correction_read` / `profile_read` policies, for one attendance record.
/// Never connects to a real database.
class FakeCorrectionServer implements DatabaseServices {
  /// `auth.uid()` and whether `profiles.role` is admin.
  String actor = employeeId;
  bool actorIsAdmin = false;

  Map<String, dynamic> record = closedRecordJson();
  final rows = <Map<String, dynamic>>[];

  /// Fail the next call with this, then work normally.
  Object? nextError;

  final rpcCalls = <(String, Map<String, dynamic>?)>[];
  final reads = <(String, String?, Map<String, dynamic>?)>[];
  int _ids = 0;

  void actAs(String id, {bool admin = false}) {
    actor = id;
    actorIsAdmin = admin;
  }

  void _failIfAsked() {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
  }

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
    reads.add((path, column, query));
    _failIfAsked();
    if (path != 'attendance_correction_requests') {
      throw UnimplementedError(path);
    }
    // RLS: your own rows, or everyone's for an admin.
    final visible = rows.where(
      (row) => actorIsAdmin || row['employee_id'] == actor,
    );
    final matches = visible
        .where(
          (row) => query?.entries.every((e) => row[e.key] == e.value) ?? true,
        )
        .toList();
    if (orderBy != null) {
      matches.sort(
        (a, b) => (a[orderBy] as String).compareTo(b[orderBy] as String),
      );
      if (descending) matches.setAll(0, matches.reversed.toList());
    }
    final embed = column?.contains('employee:profiles!') ?? false;
    return [
      for (final row in matches)
        {
          ...row,
          if (embed) ...{
            'employee': {'full_name': 'Mona Ali', 'employee_code': 'EMP-7'},
            'attendance': {
              'work_date': record['work_date'],
              'timezone': record['timezone'],
              'actual_checkin': record['actual_checkin'],
            },
          },
        },
    ];
  }

  @override
  Future<dynamic> rpc({
    required String function,
    Map<String, dynamic>? params,
  }) async {
    rpcCalls.add((function, params));
    _failIfAsked();
    return switch (function) {
      'request_attendance_correction' => _request(params!),
      'review_request' => _review(params!),
      _ => throw UnimplementedError(function),
    };
  }

  static Never _raise(String message, String code) =>
      throw PostgrestException(message: message, code: code);

  /// Times the attendance day accepts, as both functions check them.
  bool _timesFit(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null) return false;
    final local = CorrectionRules.wallClock(
      record['timezone'] as String,
      checkIn,
    );
    final workDate = DateTime.parse(record['work_date'] as String);
    final scheduledEnd = DateTime.parse(record['scheduled_end'] as String);
    final deadline = DateTime.parse(record['auto_close_deadline'] as String);
    if (local.year != workDate.year ||
        local.month != workDate.month ||
        local.day != workDate.day ||
        !checkIn.isBefore(scheduledEnd)) {
      return false;
    }
    return checkOut == null ||
        !(checkOut.isBefore(checkIn) ||
            checkOut.isAfter(deadline) ||
            (record['auto_close_policy'] == 'midnight' &&
                checkOut.isAtSameMomentAs(deadline)));
  }

  String _request(Map<String, dynamic> params) {
    final reason = (params['p_reason'] as String?)?.trim() ?? '';
    if (reason.isEmpty || reason.length > 2000) {
      _raise('A reason of 1-2000 characters is required', '22023');
    }
    if (params['p_attendance_id'] != record['id'] ||
        record['employee_id'] != actor) {
      _raise('Attendance not found or not owned by you', '42501');
    }
    if (record['actual_checkout'] == null && record['auto_closed'] != true) {
      _raise('Attendance must be closed before correction', '22023');
    }
    final checkIn = DateTime.tryParse('${params['p_checkin']}');
    final checkOut = DateTime.tryParse('${params['p_checkout']}');
    if (!_timesFit(checkIn, checkOut)) {
      _raise(
        'Proposed times must match the work date and checkout deadline',
        '22023',
      );
    }
    if (rows.any(
      (row) =>
          row['attendance_id'] == record['id'] && row['status'] == 'pending',
    )) {
      _raise(
        'A pending correction already exists for this attendance',
        '23505',
      );
    }
    final id = 'request-${++_ids}';
    rows.add({
      'id': id,
      'employee_id': actor,
      'attendance_id': record['id'],
      'proposed_checkin': checkIn!.toUtc().toIso8601String(),
      'proposed_checkout': checkOut?.toUtc().toIso8601String(),
      'reason': reason,
      'status': 'pending',
      'review_note': null,
      'reviewed_at': null,
      'created_at': nextDay.add(Duration(minutes: _ids)).toIso8601String(),
    });
    return id;
  }

  void _review(Map<String, dynamic> params) {
    if (!actorIsAdmin) {
      _raise(
        'An active, password-ready authorized account is required',
        '42501',
      );
    }
    final note = params['p_note'] as String?;
    if (note != null && note.length > 2000) {
      _raise('Review note cannot exceed 2000 characters', '22023');
    }
    if (params['p_kind'] != 'correction') {
      _raise('Unknown request kind', '22023');
    }
    final row = rows
        .where((r) => r['id'] == params['p_request_id'])
        .firstOrNull;
    if (row == null) _raise('Request not found', '22023');
    if (row['employee_id'] == actor) {
      _raise('You cannot review your own request', '42501');
    }
    if (row['status'] != 'pending') {
      _raise('This request has already been reviewed', 'P0001');
    }
    final approve = params['p_approve'] as bool;
    if (approve) {
      if (!_timesFit(
        DateTime.parse(row['proposed_checkin'] as String),
        DateTime.tryParse('${row['proposed_checkout']}'),
      )) {
        _raise(
          'Proposed correction times are outside the allowed attendance period',
          '22023',
        );
      }
      record
        ..['effective_checkin'] = row['proposed_checkin']
        ..['effective_checkout'] = row['proposed_checkout']
        ..['has_correction'] = true;
    }
    final text = note?.trim();
    row
      ..['status'] = approve ? 'approved' : 'rejected'
      ..['reviewed_at'] = nextDay.toIso8601String()
      ..['review_note'] = text == null || text.isEmpty ? null : text;
  }

  // Tables are never written directly; every write is a function.
  @override
  Future<void> addData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) => throw UnimplementedError('table write');

  @override
  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) => throw UnimplementedError('table write');

  @override
  Future<void> deleteData({
    required String path,
    String? documentId,
    Map<String, dynamic>? query,
  }) => throw UnimplementedError('table write');

  @override
  Stream<dynamic> getStreamData({
    required String path,
    String? documentId,
    Map<String, dynamic>? query,
  }) => throw UnimplementedError();

  @override
  Future<bool> ifDataExist({
    required String path,
    required String documentId,
  }) => throw UnimplementedError();
}

/// One attendance day for the details and form pages.
class _OneDayRepository implements AttendanceRepository {
  _OneDayRepository(this.session);

  AttendanceSessionEntity? session;

  @override
  Future<AttendanceSessionEntity?> getSession(String id) async =>
      session?.id == id ? session : null;

  @override
  Future<AttendanceToday> getToday() async => (shift: null, session: null);

  @override
  Future<List<AttendanceSessionEntity>> getHistory({int limit = 60}) async => [
    ?session,
  ];

  @override
  Future<AttendanceSessionEntity> checkIn(AttendanceEventEntity event) =>
      throw UnimplementedError();

  @override
  Future<AttendanceSessionEntity> checkOut(
    AttendanceSessionEntity session,
    AttendanceEventEntity event,
  ) => throw UnimplementedError();
}

UserEntity adminUser() => UserEntity(
  uID: adminId,
  email: 'admin@example.com',
  fullName: 'Test Admin',
  username: 'test.admin',
  employeeCode: 'ADM-1',
  role: UserRole.admin,
  isActive: true,
  mustChangePassword: false,
);

void main() {
  group('failureFor', () {
    // The messages of the live functions, with their error codes.
    final cases = {
      ('42501', 'Attendance not found or not owned by you'):
          CorrectionFailure.notFound,
      ('42501', 'An active, password-ready authorized account is required'):
          CorrectionFailure.notAllowed,
      ('42501', 'You cannot review your own request'):
          CorrectionFailure.ownRequest,
      ('22023', 'A reason of 1-2000 characters is required'):
          CorrectionFailure.invalidReason,
      ('22023', 'Attendance must be closed before correction'):
          CorrectionFailure.notClosed,
      (
        '22023',
        'Proposed times must match the work date and checkout deadline',
      ): CorrectionFailure.invalidTimes,
      ('22023', 'No change was requested'): CorrectionFailure.noChange,
      ('23505', 'A pending correction already exists for this attendance'):
          CorrectionFailure.alreadyPending,
      ('22023', 'Request not found'): CorrectionFailure.notFound,
      ('22023', 'Review note cannot exceed 2000 characters'):
          CorrectionFailure.noteTooLong,
      ('P0001', 'This request has already been reviewed'):
          CorrectionFailure.alreadyReviewed,
      (
        'P0001',
        'Attendance changed; reject this request and ask the employee to resubmit',
      ): CorrectionFailure.attendanceChanged,
      ('P0001', 'Attendance must be closed before correction approval'):
          CorrectionFailure.notClosed,
      (
        '22023',
        'Proposed correction times are outside the allowed attendance period',
      ): CorrectionFailure.invalidTimes,
      ('PGRST202', 'Could not find the function'):
          CorrectionFailure.serviceUnavailable,
      ('PGRST301', 'JWT expired'): CorrectionFailure.notAllowed,
      ('XX000', 'something else'): CorrectionFailure.unknown,
    };
    for (final MapEntry(key: (code, message), :value) in cases.entries) {
      test('$code $message', () {
        expect(SupabaseCorrectionRepository.failureFor(code, message), value);
      });
    }
  });

  group('CorrectionRules', () {
    final session = sessionOf(closedRecordJson());

    CorrectionFailure? check(DateTime? checkIn, DateTime? checkOut) =>
        CorrectionRules.check(
          session,
          checkIn: checkIn,
          checkOut: checkOut,
          reason: 'Forgot to check out',
        );

    test('wall-clock times become instants in the day’s timezone', () {
      expect(
        CorrectionRules.onWorkDate(session, const Duration(hours: 8)),
        DateTime.utc(2026, 10, 25, 5),
      );
      expect(
        CorrectionRules.timeOfDay(session.timezone, session.checkInTime),
        const Duration(hours: 8, minutes: 7),
      );
    });

    test('accepts a check-out up to a minute before midnight', () {
      expect(check(shiftStart, DateTime.utc(2026, 10, 25, 20, 59)), isNull);
      expect(check(shiftStart, shiftStart), isNull);
    });

    test('refuses times the server refuses', () {
      expect(
        check(DateTime.utc(2026, 10, 24, 20), shiftEnd),
        CorrectionFailure.invalidTimes,
        reason: 'check-in on the day before (23:00 Cairo)',
      );
      expect(
        check(shiftEnd, shiftEnd),
        CorrectionFailure.invalidTimes,
        reason: 'check-in at the shift end',
      );
      expect(
        check(DateTime.utc(2026, 10, 25, 9), DateTime.utc(2026, 10, 25, 8)),
        CorrectionFailure.invalidTimes,
        reason: 'check-out before check-in',
      );
      expect(
        check(shiftStart, deadline),
        CorrectionFailure.invalidTimes,
        reason: 'check-out at midnight',
      );
      expect(check(shiftStart, null), CorrectionFailure.missingCheckOut);
    });

    test('needs a reason and a closed day', () {
      expect(
        CorrectionRules.check(
          session,
          checkIn: shiftStart,
          checkOut: shiftEnd,
          reason: '   ',
        ),
        CorrectionFailure.invalidReason,
      );
      expect(
        CorrectionRules.check(
          session,
          checkIn: shiftStart,
          checkOut: shiftEnd,
          reason: 'x' * 2001,
        ),
        CorrectionFailure.invalidReason,
      );
      final open = sessionOf(
        closedRecordJson()
          ..['auto_closed'] = false
          ..['auto_closed_at'] = null,
      );
      expect(
        CorrectionRules.check(
          open,
          checkIn: shiftStart,
          checkOut: shiftEnd,
          reason: 'x',
        ),
        CorrectionFailure.notClosed,
      );
    });
  });

  group('SupabaseCorrectionRepository', () {
    late FakeCorrectionServer server;
    late SupabaseCorrectionRepository employee;
    late SupabaseCorrectionRepository admin;

    setUp(() {
      server = FakeCorrectionServer();
      employee = SupabaseCorrectionRepository(
        databaseServices: server,
        currentUserId: () => employeeId,
      );
      admin = SupabaseCorrectionRepository(
        databaseServices: server,
        currentUserId: () => adminId,
      );
    });

    Future<void> submit({DateTime? checkOut}) => employee.submit(
      attendanceId: recordId,
      checkIn: DateTime.utc(2026, 10, 25, 5, 7),
      checkOut: checkOut ?? DateTime.utc(2026, 10, 25, 13, 30),
      reason: '  Phone battery died  ',
    );

    test('request, admin approval, and the day’s hours confirmed', () async {
      await submit();
      expect(server.rpcCalls.single.$1, 'request_attendance_correction');
      expect(server.rpcCalls.single.$2, {
        'p_attendance_id': recordId,
        'p_checkin': '2026-10-25T05:07:00.000Z',
        'p_checkout': '2026-10-25T13:30:00.000Z',
        'p_reason': 'Phone battery died',
      });

      final mine = await employee.getForAttendance(recordId);
      expect(mine.single.status, CorrectionStatus.pending);
      expect(server.reads.last.$3, {
        'attendance_id': recordId,
        'employee_id': employeeId,
      });

      server.actAs(adminId, admin: true);
      final queue = await admin.getPendingForReview();
      expect(server.reads.last.$3, {'status': 'pending'});
      expect(queue.single.employeeName, 'Mona Ali');
      expect(queue.single.workDate, DateTime(2026, 10, 25));
      expect(queue.single.timezone, 'Africa/Cairo');

      await admin.review(queue.single.id, approve: true, note: '  ok  ');
      expect(server.rpcCalls.last.$1, 'review_request');
      expect(server.rpcCalls.last.$2, {
        'p_kind': 'correction',
        'p_request_id': queue.single.id,
        'p_approve': true,
        'p_note': 'ok',
      });
      final day = sessionOf(server.record);
      expect(day.isVerified, isTrue);
      expect(day.needsReview, isFalse);
      expect(
        day.verifiedDuration!.worked,
        const Duration(hours: 8, minutes: 23),
      );
      expect(await admin.getPendingForReview(), isEmpty);

      server.actAs(employeeId);
      final reviewed = (await employee.getForAttendance(recordId)).single;
      expect(reviewed.status, CorrectionStatus.approved);
      expect(reviewed.reviewNote, 'ok');
    });

    test(
      'a rejection keeps the day unconfirmed and allows a new request',
      () async {
        await submit();
        server.actAs(adminId, admin: true);
        final id = (await admin.getPendingForReview()).single.id;
        await admin.review(id, approve: false, note: '   ');
        expect(server.rpcCalls.last.$2!['p_note'], isNull);
        expect(sessionOf(server.record).needsReview, isTrue);

        server.actAs(employeeId);
        await submit();
        final requests = await employee.getForAttendance(recordId);
        expect(requests.map((r) => r.status), [
          CorrectionStatus.pending,
          CorrectionStatus.rejected,
        ], reason: 'newest first');
      },
    );

    test('one pending request per day', () async {
      await submit();
      await expectLater(submit(), throwsA(CorrectionFailure.alreadyPending));
    });

    test('refuses times outside the day', () async {
      await expectLater(
        submit(checkOut: deadline),
        throwsA(CorrectionFailure.invalidTimes),
      );
    });

    test('an employee only reads their own rows, even as an admin', () async {
      await submit();
      server.actAs(adminId, admin: true);
      final adminOwn = SupabaseCorrectionRepository(
        databaseServices: server,
        currentUserId: () => adminId,
      );
      expect(await adminOwn.getForAttendance(recordId), isEmpty);
    });

    test('the admin’s queue leaves out their own requests', () async {
      server
        ..record = closedRecordJson(owner: adminId)
        ..actAs(adminId, admin: true);
      await admin.submit(
        attendanceId: recordId,
        checkIn: shiftStart,
        checkOut: shiftEnd,
        reason: 'mine',
      );
      expect(server.rows, hasLength(1));
      expect(await admin.getPendingForReview(), isEmpty);
      // The database refuses it anyway.
      await expectLater(
        admin.review(server.rows.single['id'] as String, approve: true),
        throwsA(CorrectionFailure.ownRequest),
      );
    });

    test('an employee can’t review', () async {
      await submit();
      await expectLater(
        employee.review(server.rows.single['id'] as String, approve: true),
        throwsA(CorrectionFailure.notAllowed),
      );
    });

    test('a second review is refused', () async {
      await submit();
      server.actAs(adminId, admin: true);
      final id = server.rows.single['id'] as String;
      await admin.review(id, approve: false);
      await expectLater(
        admin.review(id, approve: true),
        throwsA(CorrectionFailure.alreadyReviewed),
      );
    });

    test('no answer is a network failure; signed out is not allowed', () async {
      server.nextError = TimeoutException('lost');
      await expectLater(submit(), throwsA(CorrectionFailure.network));

      final signedOut = SupabaseCorrectionRepository(
        databaseServices: server,
        currentUserId: () => null,
      );
      await expectLater(
        signedOut.getForAttendance(recordId),
        throwsA(CorrectionFailure.notAllowed),
      );
      expect(server.reads, isEmpty);
    });

    test('malformed rows are an unknown failure', () async {
      server.rows.add({
        'id': 'x',
        'employee_id': employeeId,
        'attendance_id': recordId,
        'status': 'weird',
        'created_at': nextDay.toIso8601String(),
      });
      await expectLater(
        employee.getForAttendance(recordId),
        throwsA(CorrectionFailure.unknown),
      );
    });
  });

  group('CorrectionRequestModel', () {
    test('reads a plain row without embeds', () {
      final model = CorrectionRequestModel.fromJson({
        'id': 'r',
        'employee_id': employeeId,
        'attendance_id': recordId,
        'proposed_checkin': '2026-10-25T05:07:00+00:00',
        'proposed_checkout': null,
        'reason': 'x',
        'status': 'rejected',
        'review_note': 'no',
        'reviewed_at': '2026-10-26T09:00:00+00:00',
        'created_at': '2026-10-26T08:00:00+00:00',
      });
      expect(model.status, CorrectionStatus.rejected);
      expect(model.proposedCheckOut, isNull);
      expect(model.employeeName, isNull);
    });
  });

  group('CorrectionFormCubit', () {
    final session = sessionOf(closedRecordJson());

    test('checks the times before sending', () async {
      final repository = FakeCorrectionRepository();
      final cubit = CorrectionFormCubit(repository);
      addTearDown(cubit.close);
      await cubit.submit(
        session,
        checkIn: shiftStart,
        checkOut: deadline,
        reason: 'x',
      );
      expect(
        cubit.state,
        isA<CorrectionFormFailed>().having(
          (s) => s.failure,
          'failure',
          CorrectionFailure.invalidTimes,
        ),
      );
      expect(repository.submitted, isEmpty);
    });

    test('sends once, then reports the server’s answer', () async {
      final repository = FakeCorrectionRepository()..gate = Completer();
      final cubit = CorrectionFormCubit(repository);
      addTearDown(cubit.close);
      final first = cubit.submit(
        session,
        checkIn: shiftStart,
        checkOut: shiftEnd,
        reason: 'x',
      );
      expect(cubit.state, isA<CorrectionFormSubmitting>());
      // A double tap while sending is ignored.
      await cubit.submit(
        session,
        checkIn: shiftStart,
        checkOut: shiftEnd,
        reason: 'x',
      );
      repository.gate!.complete();
      await first;
      expect(cubit.state, isA<CorrectionFormSubmitted>());
      expect(repository.submitted, hasLength(1));

      repository.failure = CorrectionFailure.alreadyPending;
      await cubit.submit(
        session,
        checkIn: shiftStart,
        checkOut: shiftEnd,
        reason: 'x',
      );
      expect(
        (cubit.state as CorrectionFormFailed).failure,
        CorrectionFailure.alreadyPending,
      );
    });
  });

  group('PendingCorrectionsCubit', () {
    test('a reviewed request leaves the queue', () async {
      final repository = FakeCorrectionRepository(
        requests: [
          requestOf(id: 'a'),
          requestOf(id: 'b'),
        ],
      );
      final cubit = PendingCorrectionsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();

      expect(await cubit.review('a', approve: true, note: 'fine'), isNull);
      expect(repository.reviews.single, (id: 'a', approve: true, note: 'fine'));
      final state = cubit.state as PendingCorrectionsLoaded;
      expect(state.requests.map((r) => r.id), ['b']);
      expect(state.reviewing, isEmpty);
    });

    test('ignores a second tap while sending', () async {
      final repository = FakeCorrectionRepository(requests: [requestOf()])
        ..gate = Completer();
      final cubit = PendingCorrectionsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      final first = cubit.review('request-1', approve: true);
      expect((cubit.state as PendingCorrectionsLoaded).reviewing, {
        'request-1',
      });
      expect(
        await cubit.review('request-1', approve: false),
        CorrectionFailure.busy,
      );
      repository.gate!.complete();
      expect(await first, isNull);
      expect(repository.reviews, hasLength(1));
    });

    test('reviewed elsewhere: reports it and reloads the queue', () async {
      final repository = FakeCorrectionRepository(requests: [requestOf()]);
      final cubit = PendingCorrectionsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      repository.failure = CorrectionFailure.alreadyReviewed;
      expect(
        await cubit.review('request-1', approve: true),
        CorrectionFailure.alreadyReviewed,
      );
      expect(repository.loads, 2);
      // The failed reload keeps the list that is shown.
      expect(cubit.state, isA<PendingCorrectionsLoaded>());
    });

    test('a failed first load is an error', () async {
      final repository = FakeCorrectionRepository()
        ..failure = CorrectionFailure.network;
      final cubit = PendingCorrectionsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state, isA<PendingCorrectionsError>());
    });
  });

  group('Pages', () {
    Future<void> show(
      WidgetTester tester, {
      required String location,
      required AttendanceRepository attendance,
      required CorrectionRepository corrections,
      UserEntity? user,
    }) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // A fresh tree, so each call gets new cubits.
      await tester.pumpWidget(const SizedBox());
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold()),
          GoRoute(
            path: '/attendance/:id',
            builder: (_, state) =>
                AttendanceDetailsView(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/attendance/:id/correction',
            builder: (_, state) =>
                CorrectionFormView(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/corrections',
            builder: (_, _) => const PendingCorrectionsView(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, _) => const Scaffold(body: ProfileViewBody()),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AttendanceRepository>.value(value: attendance),
            RepositoryProvider<CorrectionRepository>.value(value: corrections),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => AuthCubit(
                  FakeAuthRepository(signedInUser: user ?? testUser()),
                )..start(),
              ),
              BlocProvider(create: (_) => ClockCubit(now: () => nextDay)),
              BlocProvider(create: (_) => AttendanceSessionCubit(attendance)),
              BlocProvider(create: (_) => LocaleCubit(MemoryLocaleStore())),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('employee: request a correction for a closed day', (
      tester,
    ) async {
      final corrections = FakeCorrectionRepository();
      await show(
        tester,
        location: '/attendance/$recordId',
        attendance: _OneDayRepository(sessionOf(closedRecordJson())),
        corrections: corrections,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Request correction'), 100);
      await tester.tap(find.text('Request correction'));
      await tester.pumpAndSettle();

      expect(find.text('Correct attendance'), findsOneWidget);
      expect(
        find.text('Times are in company time (Africa/Cairo).'),
        findsOneWidget,
      );
      // The check-in starts at the recorded one; the check-out is chosen.
      expect(find.text('8:07 AM'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('correctionReason')),
        'Phone died',
      );
      await tester.ensureVisible(find.text('Send request'));
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();
      expect(find.text('Select a check-out time.'), findsOneWidget);
      expect(corrections.submitted, isEmpty);

      // The picker opens at the shift end (4:00 PM Cairo).
      await tester.tap(find.byKey(const Key('correctionCheckOut')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('4:00 PM'), findsOneWidget);

      corrections.requests = [requestOf()];
      await tester.ensureVisible(find.text('Send request'));
      await tester.tap(find.text('Send request'));
      await tester.pumpAndSettle();

      expect(corrections.submitted.single, (
        attendanceId: recordId,
        checkIn: DateTime.utc(2026, 10, 25, 5, 7),
        checkOut: shiftEnd,
        reason: 'Phone died',
      ));
      // Back on the details page, reloaded: pending, no second request.
      expect(find.text('Attendance Details'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Correction request'), 100);
      expect(find.text('Pending approval'), findsOneWidget);
      expect(find.text('Request correction'), findsNothing);
    });

    testWidgets(
      'employee: a rejected request shows its note and allows another',
      (tester) async {
        await show(
          tester,
          location: '/attendance/$recordId',
          attendance: _OneDayRepository(sessionOf(closedRecordJson())),
          corrections: FakeCorrectionRepository(
            requests: [
              requestOf(status: CorrectionStatus.rejected, note: 'Wrong times'),
            ],
          ),
        );
        await tester.scrollUntilVisible(find.text('Request correction'), 100);
        expect(find.text('Rejected'), findsOneWidget);
        expect(find.text('Reviewer note: Wrong times'), findsOneWidget);
      },
    );

    testWidgets('employee: a checked-out day has no correction section', (
      tester,
    ) async {
      final corrections = FakeCorrectionRepository();
      await show(
        tester,
        location: '/attendance/$recordId',
        attendance: _OneDayRepository(
          sessionOf(
            closedRecordJson()
              ..['auto_closed'] = false
              ..['auto_closed_at'] = null
              ..['actual_checkout'] = shiftEnd.toIso8601String(),
          ),
        ),
        corrections: corrections,
      );
      expect(find.text('Request correction'), findsNothing);
      expect(corrections.loads, 0);
    });

    testWidgets('admin: approve a pending request with a note', (tester) async {
      final corrections = FakeCorrectionRepository(requests: [requestOf()]);
      await show(
        tester,
        location: '/admin/corrections',
        attendance: _OneDayRepository(null),
        corrections: corrections,
        user: adminUser(),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Mona Ali · EMP-7'), findsOneWidget);
      expect(find.text('Recorded check-in'), findsOneWidget);

      await tester.tap(find.byKey(const Key('approve-request-1')));
      await tester.pumpAndSettle();
      expect(find.text('Approve this correction?'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('reviewNote')), 'Confirmed');
      await tester.tap(find.byKey(const Key('confirmReview')));
      await tester.pumpAndSettle();

      expect(corrections.reviews.single, (
        id: 'request-1',
        approve: true,
        note: 'Confirmed',
      ));
      expect(find.text('Correction approved.'), findsOneWidget);
      expect(find.text('No pending requests'), findsOneWidget);
    });

    testWidgets('admin: a cancelled dialog sends nothing; failures are shown', (
      tester,
    ) async {
      final corrections = FakeCorrectionRepository(requests: [requestOf()]);
      await show(
        tester,
        location: '/admin/corrections',
        attendance: _OneDayRepository(null),
        corrections: corrections,
        user: adminUser(),
      );
      await tester.tap(find.byKey(const Key('reject-request-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(corrections.reviews, isEmpty);

      corrections.failure = CorrectionFailure.ownRequest;
      await tester.tap(find.byKey(const Key('reject-request-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmReview')));
      await tester.pumpAndSettle();
      expect(find.text('You can’t review your own request.'), findsOneWidget);
      expect(find.text('Mona Ali · EMP-7'), findsOneWidget);
    });

    testWidgets('profile: the review entry is for admins only', (tester) async {
      await show(
        tester,
        location: '/profile',
        attendance: _OneDayRepository(null),
        corrections: FakeCorrectionRepository(),
      );
      expect(find.byKey(const Key('adminDashboard')), findsNothing);

      await show(
        tester,
        location: '/profile',
        attendance: _OneDayRepository(null),
        corrections: FakeCorrectionRepository(),
        user: adminUser(),
      );
      expect(find.byKey(const Key('adminDashboard')), findsOneWidget);
    });
  });

  testWidgets('withAppProviders provides a correction repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      withAppProviders(
        Builder(
          builder: (context) {
            context.read<CorrectionRepository>();
            return const SizedBox();
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
