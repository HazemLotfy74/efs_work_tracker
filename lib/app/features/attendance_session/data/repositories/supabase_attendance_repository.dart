import 'dart:developer';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../../core/constants/constants.dart';
import '../../../../../core/errors/attendance_errors.dart';
import '../../../../../core/services/database_services.dart';
import '../../../../../core/services/storage_services.dart';
import '../../domain/entities/attendance_event_entity.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../../domain/entities/attendance_type.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_session_model.dart';
import '../models/shift_model.dart';

/// Attendance on the existing database, unchanged:
/// - reads `profiles` → `work_schedules` → `schedule_days`, and
///   `attendance_records` + `attendance_events`, all through their RLS
///   policies (own rows only);
/// - writes only through the existing functions `check_in` and `check_out`,
///   which take the employee from the session and set every time
///   themselves. The app sends only the evidence.
///
/// Retries are safe. Each selfie gets one Storage path, reused on every
/// retry, and the database stores that path on exactly one event. After an
/// unclear failure (lost response, or "already done"), today's attendance is
/// reloaded: if it holds an event with this selfie path, the earlier attempt
/// was saved and its result is returned instead of an error.
class SupabaseAttendanceRepository implements AttendanceRepository {
  SupabaseAttendanceRepository({
    required this._databaseServices,
    required this._storageServices,
    required this._currentUserId,
    this._now = DateTime.now,
    this.timeout = const Duration(seconds: 20),
  });

  final DatabaseServices _databaseServices;
  final StorageServices _storageServices;
  final String? Function() _currentUserId;

  /// The device clock. Only used to find today's work date and to avoid
  /// requests the database would refuse; the database's own clock decides.
  final DateTime Function() _now;

  /// Longest wait for one request before its outcome is treated as unknown.
  final Duration timeout;

  /// Local selfie file → its Storage path.
  final Map<String, String> _selfiePaths = {};

  static const _profileColumns =
      'schedule_id, '
      'work_schedules(timezone, grace_minutes, '
      'schedule_days(weekday, starts_at, ends_at))';

  static const _recordColumns =
      'id, work_date, timezone, scheduled_start, scheduled_end, '
      'grace_minutes, actual_checkin, actual_checkout, auto_closed, '
      'auto_closed_at, auto_close_policy, auto_close_deadline, '
      'effective_checkin, effective_checkout, has_correction, '
      'late_minutes, attendance_events(event_type, occurred_at, latitude, '
      'longitude, accuracy_m, selfie_path)';

  @override
  Future<AttendanceToday> getToday() async {
    final userId = _currentUserId();
    if (userId == null) throw AttendanceFailure.accountNotReady;

    // RLS shows your own profile only while the account is active and the
    // password is changed; otherwise there is no row.
    final profile = await _guard(
      'profiles',
      () => _databaseServices.getData(
        path: 'profiles',
        documentId: userId,
        column: _profileColumns,
      ),
    );
    if (profile == null) throw AttendanceFailure.accountNotReady;

    final ShiftEntity? shift;
    final String workDate;
    try {
      final schedule = (profile as Map)['work_schedules'] as Map?;
      if (schedule == null) throw AttendanceFailure.noSchedule;

      // The work date is the date in the schedule's timezone, as in check_in.
      final location = ShiftModel.locationNamed(schedule['timezone'] as String);
      final businessNow = tz.TZDateTime.from(_now(), location);
      workDate = _dateText(businessNow);

      // Postgres weekday: Sunday 0 … Saturday 6.
      final weekday = businessNow.weekday % 7;
      final day = (schedule['schedule_days'] as List)
          .cast<Map>()
          .where((d) => (d['weekday'] as num).toInt() == weekday)
          .firstOrNull;
      shift = day == null
          ? null
          : ShiftModel.fromScheduleDay(
              Map<String, dynamic>.from(day),
              location: location,
              businessDate: businessNow,
              graceMinutes: (schedule['grace_minutes'] as num).toInt(),
            );
    } on AttendanceFailure {
      rethrow;
    } catch (e) {
      log('Unreadable schedule: ${e.runtimeType}');
      throw AttendanceFailure.unknown;
    }

    final rows = await _guard(
      'attendance_records',
      () => _databaseServices.getData(
        path: 'attendance_records',
        column: _recordColumns,
        query: {'employee_id': userId, 'work_date': workDate},
      ),
    );
    final AttendanceSessionEntity? session;
    try {
      final records = (rows as List).cast<Map>();
      // unique (employee_id, work_date) allows at most one.
      if (records.length > 1) throw const FormatException('Two records');
      session = records.isEmpty
          ? null
          : AttendanceSessionModel.fromJson(
              Map<String, dynamic>.from(records.single),
              shift: shift ?? ShiftEntity.standard,
            );
    } catch (e) {
      // Malformed data: show an error rather than a wrong attendance state.
      log('Unreadable attendance data: ${e.runtimeType}');
      throw AttendanceFailure.unknown;
    }
    return (shift: shift, session: session);
  }

  @override
  Future<List<AttendanceSessionEntity>> getHistory({int limit = 60}) async {
    final userId = _currentUserId();
    if (userId == null) throw AttendanceFailure.accountNotReady;
    // Filtered by employee: an admin's RLS policy shows everyone's rows.
    final rows = await _guard(
      'attendance_records',
      () => _databaseServices.getData(
        path: 'attendance_records',
        column: _recordColumns,
        query: {'employee_id': userId},
        orderBy: 'work_date',
        descending: true,
        limit: limit,
      ),
    );
    try {
      return [
        for (final row in (rows as List).cast<Map>())
          _recordFromJson(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      log('Unreadable attendance history: ${e.runtimeType}');
      throw AttendanceFailure.unknown;
    }
  }

  @override
  Future<AttendanceSessionEntity?> getSession(String id) async {
    final userId = _currentUserId();
    if (userId == null) throw AttendanceFailure.accountNotReady;
    final rows = await _guard(
      'attendance_records',
      () => _databaseServices.getData(
        path: 'attendance_records',
        column: _recordColumns,
        query: {'id': id, 'employee_id': userId},
      ),
    );
    try {
      final records = (rows as List).cast<Map>();
      if (records.isEmpty) return null;
      return _recordFromJson(Map<String, dynamic>.from(records.single));
    } catch (e) {
      log('Unreadable attendance record: ${e.runtimeType}');
      throw AttendanceFailure.unknown;
    }
  }

  /// A record with the schedule it was saved with. Overtime is part of its
  /// worked time (beyond 8 hours), never read from overtime requests.
  static AttendanceSessionEntity _recordFromJson(Map<String, dynamic> json) =>
      AttendanceSessionModel.fromJson(json, shift: ShiftModel.fromRecord(json));

  @override
  Future<AttendanceSessionEntity> checkIn(AttendanceEventEntity event) async {
    final location = _requireLocation(event);
    final selfiePath = await _uploadSelfie(event);
    try {
      await _call('check_in', {
        'p_latitude': location.latitude,
        'p_longitude': location.longitude,
        'p_accuracy_m': location.accuracyMeters,
        'p_selfie_path': selfiePath,
      });
    } on AttendanceFailure catch (failure) {
      if (failure == AttendanceFailure.alreadyCheckedIn ||
          failure == AttendanceFailure.network) {
        return _reconcile(AttendanceType.checkIn, selfiePath, failure);
      }
      rethrow;
    }
    return _confirm(AttendanceType.checkIn, selfiePath);
  }

  /// `check_out` saves nothing once `auto_close_deadline` has passed (or the
  /// day was closed automatically), yet still answers with the record id.
  /// So a check-out is only sent while the session is active, and its
  /// result is always confirmed by reading the record back.
  @override
  Future<AttendanceSessionEntity> checkOut(
    AttendanceSessionEntity session,
    AttendanceEventEntity event,
  ) async {
    if (session.checkOut != null) throw AttendanceFailure.alreadyCheckedOut;
    if (!session.isActiveAt(_now())) {
      throw AttendanceFailure.closedAutomatically;
    }
    final location = _requireLocation(event);
    final selfiePath = await _uploadSelfie(event);
    try {
      await _call('check_out', {
        'p_attendance_id': session.id,
        'p_latitude': location.latitude,
        'p_longitude': location.longitude,
        'p_accuracy_m': location.accuracyMeters,
        'p_selfie_path': selfiePath,
      });
    } on AttendanceFailure catch (failure) {
      if (failure == AttendanceFailure.alreadyCheckedOut ||
          failure == AttendanceFailure.network) {
        return _reconcile(AttendanceType.checkOut, selfiePath, failure);
      }
      rethrow;
    }
    return _confirm(AttendanceType.checkOut, selfiePath);
  }

  /// The request was answered: returns the session it saved.
  Future<AttendanceSessionEntity> _confirm(
    AttendanceType type,
    String selfiePath,
  ) async {
    final AttendanceToday today;
    try {
      today = await getToday();
    } on AttendanceFailure {
      // Saved, but it can't be shown yet. Reloading later will show it, and
      // a retry is matched to this save by its selfie.
      throw AttendanceFailure.outcomeUnknown;
    }
    return _withSelfie(today.session, type, selfiePath) ??
        (throw _unsaved(today.session, type, AttendanceFailure.outcomeUnknown));
  }

  /// The request may have been saved: returns the saved session if so,
  /// otherwise throws [failure].
  Future<AttendanceSessionEntity> _reconcile(
    AttendanceType type,
    String selfiePath,
    AttendanceFailure failure,
  ) async {
    final AttendanceToday today;
    try {
      today = await getToday();
    } on AttendanceFailure {
      throw AttendanceFailure.outcomeUnknown;
    }
    return _withSelfie(today.session, type, selfiePath) ??
        (throw _unsaved(today.session, type, failure));
  }

  /// Why nothing was saved. A check-out that met the shift end on the
  /// server finds the day closed automatically instead.
  static AttendanceFailure _unsaved(
    AttendanceSessionEntity? session,
    AttendanceType type,
    AttendanceFailure otherwise,
  ) {
    if (type == AttendanceType.checkOut &&
        session != null &&
        session.checkOut == null &&
        session.isAutoClosed) {
      return AttendanceFailure.closedAutomatically;
    }
    return otherwise;
  }

  static AttendanceSessionEntity? _withSelfie(
    AttendanceSessionEntity? session,
    AttendanceType type,
    String selfiePath,
  ) {
    final event = switch (type) {
      AttendanceType.checkIn => session?.checkIn,
      AttendanceType.checkOut => session?.checkOut,
    };
    return event?.selfiePath == selfiePath ? session : null;
  }

  static LocationEntity _requireLocation(AttendanceEventEntity event) {
    if (event.selfiePath == null) throw AttendanceFailure.selfieMissing;
    return event.location ?? (throw AttendanceFailure.invalidLocation);
  }

  /// Uploads the event's selfie once and returns its Storage path:
  /// `<user id>/<uuid>.<ext>`, as the bucket's policy requires.
  Future<String> _uploadSelfie(AttendanceEventEntity event) async {
    final localPath = event.selfiePath!;
    final userId = _currentUserId();
    if (userId == null) throw AttendanceFailure.accountNotReady;

    // From the extension; a web browser's `blob:` URL has none, so then
    // from the photo's own bytes.
    var type = switch (localPath.split('.').last.toLowerCase()) {
      'jpg' || 'jpeg' => 'jpg',
      'png' => 'png',
      'webp' => 'webp',
      _ => null,
    };
    if (type == null) {
      try {
        type = await _storageServices.imageTypeOf(localPath).timeout(timeout);
      } catch (e) {
        log('Selfie unreadable: ${e.runtimeType}');
      }
    }
    final (extension, contentType) = switch (type) {
      'jpg' => ('jpg', 'image/jpeg'),
      'png' => ('png', 'image/png'),
      'webp' => ('webp', 'image/webp'),
      // The bucket only accepts these three types.
      _ => throw AttendanceFailure.selfieUploadFailed,
    };

    var path = _selfiePaths[localPath];
    // Never reuse a path made for another signed-in account.
    if (path == null || !path.startsWith('$userId/')) {
      path = '$userId/${_uuidV4()}.$extension';
      _selfiePaths[localPath] = path;
    }

    try {
      await _storageServices
          .uploadFile(
            bucket: Constants.attendanceEvidenceBucket,
            path: path,
            localPath: localPath,
            contentType: contentType,
          )
          .timeout(timeout);
    } catch (e) {
      log('Selfie upload failed: ${e.runtimeType}');
      throw AttendanceFailure.selfieUploadFailed;
    }
    return path;
  }

  Future<Object?> _call(String function, [Map<String, dynamic>? params]) {
    return _guard(
      function,
      () => _databaseServices.rpc(function: function, params: params),
    );
  }

  /// Runs one request with the timeout and turns its errors into failures.
  Future<Object?> _guard(
    String name,
    Future<dynamic> Function() request,
  ) async {
    try {
      return await request().timeout(timeout);
    } on PostgrestException catch (e) {
      log('$name failed: code ${e.code}');
      throw failureFor(e.code, e.message);
    } on AttendanceFailure {
      rethrow;
    } on Exception catch (e) {
      // No answer (offline, timeout): the request may still have been saved.
      log('$name failed: ${e.runtimeType}');
      throw AttendanceFailure.network;
    }
  }

  static String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Maps a database error from the attendance tables and functions.
  @visibleForTesting
  static AttendanceFailure failureFor(String? code, String message) {
    switch (code) {
      case '42501':
        return message.startsWith('Attendance record not found')
            ? AttendanceFailure.notCheckedIn
            : AttendanceFailure.accountNotReady;
      // unique (employee_id, work_date): today's check-in already exists.
      case '23505':
        return AttendanceFailure.alreadyCheckedIn;
      case '22023':
        return message.toLowerCase().contains('selfie')
            ? AttendanceFailure.selfieMissing
            : AttendanceFailure.invalidLocation;
      // Function or table not found in the API.
      case 'PGRST202' || 'PGRST205':
        return AttendanceFailure.serviceUnavailable;
      // Expired or invalid access token.
      case 'PGRST301' || 'PGRST303':
        return AttendanceFailure.accountNotReady;
    }
    // The remaining errors are plain `raise exception` (code P0001), so the
    // message is all that tells them apart.
    for (final (prefix, failure) in _messageFailures) {
      if (message.startsWith(prefix)) return failure;
    }
    return AttendanceFailure.unknown;
  }

  static const _messageFailures = [
    ('No assigned work schedule', AttendanceFailure.noSchedule),
    ('There is no scheduled shift today', AttendanceFailure.notWorkingDay),
    (
      'The shift has ended; check-in is closed',
      AttendanceFailure.checkInClosed,
    ),
    ('The working date changed', AttendanceFailure.workDateChanged),
    ('Checkout was already recorded', AttendanceFailure.alreadyCheckedOut),
  ];

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
