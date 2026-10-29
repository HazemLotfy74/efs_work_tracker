import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/correction_errors.dart';
import '../../../../../core/services/database_services.dart';
import '../../domain/entities/correction_request_entity.dart';
import '../../domain/repositories/correction_repository.dart';
import '../models/correction_request_model.dart';

/// Correction requests on the existing database, unchanged:
/// - reads `attendance_correction_requests` through its RLS policy, which
///   shows an employee their own rows and an admin everyone's;
/// - writes only through the existing functions
///   `request_attendance_correction` (employee) and
///   `review_request('correction', …)` (admin). Both take the account from
///   the session and check every rule themselves; `review_request` also
///   refuses non-admins and their own requests.
///
/// Retries are safe: a second request for the same day is refused while
/// one is pending, and a second review is refused once reviewed.
class SupabaseCorrectionRepository implements CorrectionRepository {
  SupabaseCorrectionRepository({
    required this._databaseServices,
    required this._currentUserId,
    this.timeout = const Duration(seconds: 20),
  });

  final DatabaseServices _databaseServices;
  final String? Function() _currentUserId;

  /// Longest wait for one request.
  final Duration timeout;

  static const _table = 'attendance_correction_requests';

  static const _columns =
      'id, employee_id, attendance_id, proposed_checkin, proposed_checkout, '
      'reason, status, review_note, reviewed_at, created_at';

  // Two foreign keys lead to `profiles` (employee_id, reviewed_by), so the
  // employee's one is named.
  static const _reviewColumns =
      '$_columns, '
      'employee:profiles!attendance_correction_requests_employee_id_fkey'
      '(full_name, employee_code), '
      'attendance:attendance_records(work_date, timezone, actual_checkin)';

  @override
  Future<List<CorrectionRequestEntity>> getForAttendance(
    String attendanceId,
  ) async {
    final userId = _requireUser();
    // Filtered by employee: an admin's RLS policy shows everyone's rows.
    final rows = await _guard(
      _table,
      () => _databaseServices.getData(
        path: _table,
        column: _columns,
        query: {'attendance_id': attendanceId, 'employee_id': userId},
        orderBy: 'created_at',
        descending: true,
      ),
    );
    return _parse(rows);
  }

  @override
  Future<void> submit({
    required String attendanceId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  }) async {
    _requireUser();
    await _guard(
      'request_attendance_correction',
      () => _databaseServices.rpc(
        function: 'request_attendance_correction',
        params: {
          'p_attendance_id': attendanceId,
          'p_checkin': checkIn.toUtc().toIso8601String(),
          'p_checkout': checkOut.toUtc().toIso8601String(),
          'p_reason': reason.trim(),
        },
      ),
    );
  }

  @override
  Future<List<CorrectionRequestEntity>> getPendingForReview() async {
    final userId = _requireUser();
    final rows = await _guard(
      _table,
      () => _databaseServices.getData(
        path: _table,
        column: _reviewColumns,
        query: {'status': 'pending'},
        orderBy: 'created_at',
      ),
    );
    return [
      for (final request in _parse(rows))
        if (request.employeeId != userId) request,
    ];
  }

  @override
  Future<void> review(
    String requestId, {
    required bool approve,
    String? note,
  }) async {
    _requireUser();
    final text = note?.trim();
    await _guard(
      'review_request',
      () => _databaseServices.rpc(
        function: 'review_request',
        params: {
          'p_kind': 'correction',
          'p_request_id': requestId,
          'p_approve': approve,
          'p_note': text == null || text.isEmpty ? null : text,
        },
      ),
    );
  }

  String _requireUser() =>
      _currentUserId() ?? (throw CorrectionFailure.notAllowed);

  static List<CorrectionRequestEntity> _parse(Object? rows) {
    try {
      return [
        for (final row in (rows as List).cast<Map>())
          CorrectionRequestModel.fromJson(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      log('Unreadable correction requests: ${e.runtimeType}');
      throw CorrectionFailure.unknown;
    }
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
    } on CorrectionFailure {
      rethrow;
    } on Exception catch (e) {
      log('$name failed: ${e.runtimeType}');
      throw CorrectionFailure.network;
    }
  }

  /// Maps a database error from the correction functions and table.
  @visibleForTesting
  static CorrectionFailure failureFor(String? code, String message) {
    for (final (prefix, failure) in _messageFailures) {
      if (message.startsWith(prefix)) return failure;
    }
    return switch (code) {
      // require_actor: inactive, password not changed, or not an admin.
      '42501' => CorrectionFailure.notAllowed,
      // The partial unique index: one pending request per day.
      '23505' => CorrectionFailure.alreadyPending,
      '22023' => CorrectionFailure.invalidTimes,
      // Function or table not found in the API.
      'PGRST202' || 'PGRST205' => CorrectionFailure.serviceUnavailable,
      // Expired or invalid access token.
      'PGRST301' || 'PGRST303' => CorrectionFailure.notAllowed,
      _ => CorrectionFailure.unknown,
    };
  }

  // The messages raised by request_attendance_correction and review_request.
  static const _messageFailures = [
    ('Attendance not found or not owned by you', CorrectionFailure.notFound),
    ('Attendance record not found', CorrectionFailure.notFound),
    ('Request not found', CorrectionFailure.notFound),
    ('You cannot review your own request', CorrectionFailure.ownRequest),
    ('A reason of 1-2000 characters', CorrectionFailure.invalidReason),
    ('Review note cannot exceed', CorrectionFailure.noteTooLong),
    ('Attendance must be closed', CorrectionFailure.notClosed),
    ('Proposed', CorrectionFailure.invalidTimes),
    ('No change was requested', CorrectionFailure.noChange),
    ('A pending correction already exists', CorrectionFailure.alreadyPending),
    (
      'This request has already been reviewed',
      CorrectionFailure.alreadyReviewed,
    ),
    ('Attendance changed', CorrectionFailure.attendanceChanged),
  ];
}
