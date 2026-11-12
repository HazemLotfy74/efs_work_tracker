import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../../core/constants/constants.dart';
import '../../../../../core/errors/admin_errors.dart';
import '../../../../../core/services/accounts_function.dart';
import '../../../../../core/services/database_services.dart';
import '../../../../../core/services/storage_services.dart';
import '../../../attendance_correction/data/models/correction_request_model.dart';
import '../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../attendance_session/data/models/attendance_session_model.dart';
import '../../../attendance_session/data/models/shift_model.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/admin_request_entity.dart';
import '../../domain/entities/audit_entry_entity.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/repositories/admin_repository.dart';

/// [AdminRepository] on the existing database, unchanged: reads through
/// the admin RLS policies, reviews through `review_request`, and creates
/// accounts through the `employee-accounts` Edge Function.
class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository({
    required this._databaseServices,
    required this._storageServices,
    required this._accountsFunction,
    required this._currentUserId,
    this._now = DateTime.now,
    this.timeout = const Duration(seconds: 20),
    this.isWeb = kIsWeb,
    this.sendsRole = Constants.accountRoleAndPhone,
  });

  /// Running in a web browser, where CORS applies.
  final bool isWeb;

  /// The backend accepts a role for new accounts (see
  /// `Constants.accountRoleAndPhone`); otherwise it is never sent.
  final bool sendsRole;

  final DatabaseServices _databaseServices;
  final StorageServices _storageServices;
  final AccountsFunction _accountsFunction;
  final String? Function() _currentUserId;

  /// Only used to find today's work date; the database's clock decides.
  final DateTime Function() _now;
  final Duration timeout;

  static const _baseEmployeeColumns =
      'id, full_name, username, employee_code, role, is_active, '
      'must_change_password, schedule_id, created_at, '
      'can_review_expense_advances, can_review_attendance_corrections';

  /// `profiles.phone` only exists once the role-and-phone migration ran.
  String get _employeeColumns =>
      sendsRole ? '$_baseEmployeeColumns, phone' : _baseEmployeeColumns;

  /// A day's times and flags, without its evidence: lists only need these.
  static const summaryColumns =
      'id, employee_id, work_date, timezone, scheduled_start, scheduled_end, '
      'grace_minutes, actual_checkin, actual_checkout, auto_closed, '
      'auto_closed_at, auto_close_policy, auto_close_deadline, '
      'effective_checkin, effective_checkout, has_correction, late_minutes';

  /// A day with its check-in / check-out evidence (photos, locations), for
  /// the one day being looked at.
  static const recordColumns =
      '$summaryColumns, '
      'attendance_events(event_type, occurred_at, latitude, longitude, '
      'accuracy_m, selfie_path)';

  static String _requestColumns(String table, String extra) =>
      'id, employee_id, reason, created_at, $extra, '
      'employee:profiles!${table}_employee_id_fkey(full_name, employee_code)';

  @override
  Future<List<EmployeeEntity>> getEmployees() async {
    _requireUser();
    final rows = await _guard(
      'profiles',
      () => _databaseServices.getData(
        path: 'profiles',
        column: _employeeColumns,
        orderBy: 'full_name',
      ),
    );
    return _parse('profiles', rows, _employee);
  }

  static EmployeeEntity _employee(Map<String, dynamic> json) {
    final createdAt = json['created_at'] as String?;
    return EmployeeEntity(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      employeeCode: json['employee_code'] as String,
      role: UserRole.fromName(json['role'] as String?),
      isActive: json['is_active'] == true,
      mustChangePassword: json['must_change_password'] != false,
      scheduleId: json['schedule_id'] as String,
      createdAt: createdAt == null ? null : DateTime.parse(createdAt),
      phone: json['phone'] as String?,
      canReviewCash: json['can_review_expense_advances'] == true,
      canReviewCorrections: json['can_review_attendance_corrections'] == true,
    );
  }

  @override
  Future<EmployeeEntity?> getEmployee(String id) async {
    _requireUser();
    final rows = await _guard(
      'profiles',
      () => _databaseServices.getData(
        path: 'profiles',
        column: _employeeColumns,
        query: {'id': id},
      ),
    );
    return _parse('profiles', rows, _employee).firstOrNull;
  }

  @override
  Future<EmployeeDay?> getDay(String attendanceId) async {
    _requireUser();
    final rows = await _guard(
      'attendance_records',
      () => _databaseServices.getData(
        path: 'attendance_records',
        column: recordColumns,
        query: {'id': attendanceId},
      ),
    );
    return _parse('attendance_records', rows, _employeeDay).firstOrNull;
  }

  static EmployeeDay _employeeDay(Map<String, dynamic> json) =>
      (employeeId: json['employee_id'] as String, session: _session(json));

  @override
  Future<List<CorrectionRequestEntity>> getCorrections(
    String employeeId,
  ) async {
    _requireUser();
    final rows = await _guard(
      'attendance_correction_requests',
      () => _databaseServices.getData(
        path: 'attendance_correction_requests',
        column:
            'id, employee_id, attendance_id, proposed_checkin, '
            'proposed_checkout, reason, status, review_note, reviewed_at, '
            'created_at',
        query: {'employee_id': employeeId},
        orderBy: 'created_at',
        descending: true,
      ),
    );
    return _parse(
      'attendance_correction_requests',
      rows,
      CorrectionRequestModel.fromJson,
    );
  }

  @override
  Future<String> evidenceUrl(String selfiePath) async {
    _requireUser();
    final url = await _guard(
      'evidence',
      () => _storageServices.signedUrl(
        bucket: Constants.attendanceEvidenceBucket,
        path: selfiePath,
        expiresIn: const Duration(minutes: 10),
      ),
    );
    return url as String;
  }

  @override
  Future<void> setEmployeeActive(
    String employeeId, {
    required bool active,
  }) async {
    _requireUser();
    await _guard(
      'admin_set_employee_active',
      () => _databaseServices.rpc(
        function: 'admin_set_employee_active',
        params: {'p_employee_id': employeeId, 'p_is_active': active},
      ),
    );
  }

  @override
  Future<void> correctAttendance(
    String attendanceId, {
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  }) async {
    _requireUser();
    await _guard(
      'admin_correct_attendance',
      () => _databaseServices.rpc(
        function: 'admin_correct_attendance',
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
  Future<void> assignSchedule(String employeeId, String scheduleId) async {
    _requireUser();
    await _guard(
      'admin_assign_schedule',
      () => _databaseServices.rpc(
        function: 'admin_assign_schedule',
        params: {'p_employee_id': employeeId, 'p_schedule_id': scheduleId},
      ),
    );
  }

  @override
  Future<List<AuditEntryEntity>> getAuditHistory(
    String employeeId, {
    int limit = 200,
  }) async {
    _requireUser();
    Future<Object?> read(String filter) => _guard(
      'audit_logs',
      () => _databaseServices.getData(
        path: 'audit_logs',
        column:
            'id, actor_id, actor_kind, action, table_name, row_key, '
            'old_data, new_data, happened_at',
        query: {filter: employeeId},
        orderBy: 'happened_at',
        descending: true,
        limit: limit,
      ),
    );
    // The profile itself, and every row that names the employee
    // (attendance days, requests, corrections).
    final own = await read('row_key->>id');
    final related = await read('new_data->>employee_id');
    final byId = <int, AuditEntryEntity>{
      for (final entry in [
        ..._parse('audit_logs', own, _auditEntry),
        ..._parse('audit_logs', related, _auditEntry),
      ])
        entry.id: entry,
    };
    final entries = byId.values.toList()
      ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return entries.take(limit).toList();
  }

  static AuditEntryEntity _auditEntry(Map<String, dynamic> json) {
    Map<String, dynamic>? map(Object? value) =>
        value is Map ? Map<String, dynamic>.from(value) : null;
    return AuditEntryEntity(
      id: (json['id'] as num).toInt(),
      actorId: json['actor_id'] as String?,
      actorKind: json['actor_kind'] as String? ?? 'database',
      action: json['action'] as String,
      table: json['table_name'] as String,
      rowId: map(json['row_key'])?['id'] as String?,
      happenedAt: DateTime.parse(json['happened_at'] as String),
      changes: AuditEntryEntity.diff(
        map(json['old_data']),
        map(json['new_data']),
      ),
    );
  }

  @override
  Future<List<WorkScheduleOption>> getSchedules() async {
    _requireUser();
    final rows = await _guard(
      'work_schedules',
      () => _databaseServices.getData(
        path: 'work_schedules',
        column: 'id, name, timezone',
        orderBy: 'name',
      ),
    );
    return _parse(
      'work_schedules',
      rows,
      (json) => WorkScheduleOption(
        id: json['id'] as String,
        name: json['name'] as String,
        timezone: json['timezone'] as String,
      ),
    );
  }

  @override
  Future<Map<String, AttendanceSessionEntity>> getToday(
    List<EmployeeEntity> employees,
    List<WorkScheduleOption> schedules,
  ) async {
    _requireUser();
    // Today's work date in each schedule's timezone, as check_in sets it.
    final timezones = {for (final s in schedules) s.id: s.timezone};
    final dates = <String>{
      for (final employee in employees)
        if (timezones[employee.scheduleId] case final zone?) _today(zone),
    };
    final result = <String, AttendanceSessionEntity>{};
    for (final date in dates) {
      final rows = await _guard(
        'attendance_records',
        () => _databaseServices.getData(
          path: 'attendance_records',
          column: summaryColumns,
          query: {'work_date': date},
        ),
      );
      final sessions = _parse('attendance_records', rows, (json) {
        return (json['employee_id'] as String, _session(json));
      });
      for (final (employeeId, session) in sessions) {
        result[employeeId] = session;
      }
    }
    return result;
  }

  @override
  Future<List<EmployeeDay>> getRecentDays({int limit = 300}) async {
    _requireUser();
    final rows = await _guard(
      'attendance_records',
      () => _databaseServices.getData(
        path: 'attendance_records',
        column: summaryColumns,
        orderBy: 'work_date',
        descending: true,
        limit: limit,
      ),
    );
    return _parse('attendance_records', rows, (json) {
      return (
        employeeId: json['employee_id'] as String,
        session: _session(json),
      );
    });
  }

  @override
  Future<List<AttendanceSessionEntity>> getHistory(
    String employeeId, {
    int limit = 60,
  }) async {
    _requireUser();
    final rows = await _guard(
      'attendance_records',
      () => _databaseServices.getData(
        path: 'attendance_records',
        column: summaryColumns,
        query: {'employee_id': employeeId},
        orderBy: 'work_date',
        descending: true,
        limit: limit,
      ),
    );
    return _parse('attendance_records', rows, _session);
  }

  @override
  Future<String> createEmployee(
    NewEmployeeDraft draft, {
    required String requestId,
  }) async {
    _requireUser();
    if (draft.invalidFields.isNotEmpty) throw AdminFailure.invalidInput;
    final Object? answer;
    try {
      answer = await _accountsFunction({
        'action': 'create_employee',
        'request_id': requestId,
        'full_name': draft.fullName,
        'username': draft.username,
        'email': draft.email,
        'password': draft.password,
        'employee_code': draft.employeeCode,
        'schedule_id': draft.scheduleId,
        if (sendsRole) 'role': draft.role.name,
        if (sendsRole && draft.phone != null) 'phone': draft.phone,
      }).timeout(timeout);
    } on AccountsFunctionException catch (e) {
      // A refused preflight never reaches the function, so nothing was
      // created; offline on a phone the request may have been sent.
      if (e.code == AccountsFunctionException.unreachable) {
        throw isWeb
            ? AdminFailure.webOriginBlocked
            : AdminFailure.outcomeUnknown;
      }
      throw accountFailureFor(e.status, e.code);
    } on Exception catch (e) {
      // No answer: it may have been created. The same request id is safe
      // to send again.
      log('create_employee failed: ${e.runtimeType}');
      throw AdminFailure.outcomeUnknown;
    }
    final id = answer is Map ? answer['id'] : null;
    if (id is! String) throw AdminFailure.outcomeUnknown;
    return id;
  }

  @override
  Future<List<AdminRequestEntity>> getPendingRequests() async {
    final userId = _requireUser();
    final cash = await _guard(
      'expense_advance_requests',
      () => _databaseServices.getData(
        path: 'expense_advance_requests',
        column: _requestColumns(
          'expense_advance_requests',
          'requested_amount, currency, assigned_reviewer_id',
        ),
        query: {'status': 'pending'},
        orderBy: 'created_at',
      ),
    );
    final requests = _parse('expense_advance_requests', cash, _request);
    // review_request refuses your own requests.
    return [
      for (final request in requests)
        if (request.employeeId != userId) request,
    ];
  }

  @override
  Future<void> review(
    AdminRequestEntity request, {
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
          'p_kind': AdminRequestEntity.reviewKind,
          'p_request_id': request.id,
          'p_approve': approve,
          'p_note': text == null || text.isEmpty ? null : text,
        },
      ),
    );
  }

  @override
  Future<void> editEmployee(
    String employeeId, {
    required String fullName,
    required String username,
    required String employeeCode,
  }) async {
    _requireUser();
    await _guard(
      'admin_edit_employee_profile',
      () => _databaseServices.rpc(
        function: 'admin_edit_employee_profile',
        params: {
          'p_employee_id': employeeId,
          'p_full_name': fullName,
          'p_username': username,
          'p_employee_code': employeeCode,
        },
      ),
    );
  }

  @override
  Future<LoginEmail> getLoginEmail(String employeeId) async {
    _requireUser();
    final answer = await _guard(
      'get_employee_login_email',
      () => _databaseServices.rpc(
        function: 'get_employee_login_email',
        params: {'p_employee_id': employeeId},
      ),
    );
    try {
      final json = answer as Map;
      final expiresAt = json['expires_at'] as String?;
      return (
        email: json['email'] as String,
        pendingEmail: json['pending_email'] as String?,
        expiresAt: expiresAt == null ? null : DateTime.parse(expiresAt),
      );
    } catch (e) {
      log('Unreadable login email: ${e.runtimeType}');
      throw AdminFailure.unknown;
    }
  }

  @override
  Future<void> requestEmailChange(String employeeId, String? newEmail) async {
    _requireUser();
    await _guard(
      'admin_request_employee_email_change',
      () => _databaseServices.rpc(
        function: 'admin_request_employee_email_change',
        params: {'p_employee_id': employeeId, 'p_new_email': newEmail},
      ),
    );
  }

  @override
  Future<void> assignCashReviewer(String requestId, String? reviewerId) async {
    _requireUser();
    await _guard(
      'admin_assign_expense_advance_reviewer',
      () => _databaseServices.rpc(
        function: 'admin_assign_expense_advance_reviewer',
        params: {'p_request_id': requestId, 'p_reviewer_id': reviewerId},
      ),
    );
  }

  static AttendanceSessionEntity _session(Map<String, dynamic> json) =>
      AttendanceSessionModel.fromJson(json, shift: ShiftModel.fromRecord(json));

  static AdminRequestEntity _request(Map<String, dynamic> json) {
    final employee = json['employee'] as Map?;
    final amount = json['requested_amount'];
    return AdminRequestEntity(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      employeeName: employee?['full_name'] as String?,
      employeeCode: employee?['employee_code'] as String?,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      // numeric may arrive as text when it is too precise for JSON numbers.
      amount: amount is num ? amount : num.parse(amount as String),
      currency: json['currency'] as String,
      assignedReviewerId: json['assigned_reviewer_id'] as String?,
    );
  }

  String _today(String timezone) {
    final now = tz.TZDateTime.from(_now(), ShiftModel.locationNamed(timezone));
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _requireUser() => _currentUserId() ?? (throw AdminFailure.notAllowed);

  static List<T> _parse<T>(
    String name,
    Object? rows,
    T Function(Map<String, dynamic> json) parse,
  ) {
    try {
      return [
        for (final row in (rows as List).cast<Map>())
          parse(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      log('Unreadable $name: ${e.runtimeType}');
      throw AdminFailure.unknown;
    }
  }

  Future<Object?> _guard(
    String name,
    Future<dynamic> Function() request,
  ) async {
    try {
      return await request().timeout(timeout);
    } on PostgrestException catch (e) {
      log('$name failed: code ${e.code}');
      throw failureFor(e.code, e.message);
    } on AdminFailure {
      rethrow;
    } on Exception catch (e) {
      log('$name failed: ${e.runtimeType}');
      throw AdminFailure.network;
    }
  }

  /// Maps a database error from the admin reads and `review_request`. Also
  /// used by the HR report reads.
  static AdminFailure failureFor(String? code, String message) {
    if (message.startsWith('You cannot review your own request')) {
      return AdminFailure.ownRequest;
    }
    if (message.startsWith('Employees cannot be assigned their own')) {
      return AdminFailure.ownRequest;
    }
    if (message.startsWith('This request has already been reviewed') ||
        message.startsWith('Only pending requests can be assigned')) {
      return AdminFailure.alreadyReviewed;
    }
    if (message.startsWith('Request not found') ||
        message.startsWith('Employee profile not found') ||
        message.startsWith('Employee not found') ||
        message.startsWith('Schedule not found') ||
        message.startsWith('Attendance record not found')) {
      return AdminFailure.notFound;
    }
    // admin_correct_attendance (supabase/migrations/…_admin_correct_attendance).
    for (final (prefix, failure) in _correctionFailures) {
      if (message.startsWith(prefix)) return failure;
    }
    return switch (code) {
      '42501' || 'PGRST301' || 'PGRST303' => AdminFailure.notAllowed,
      '22023' => AdminFailure.invalidInput,
      // A username, employee code or login email that is already in use.
      '23505' => AdminFailure.accountConflict,
      'PGRST202' || 'PGRST205' => AdminFailure.serviceUnavailable,
      _ => AdminFailure.unknown,
    };
  }

  static const _correctionFailures = [
    ('You cannot correct your own attendance', AdminFailure.ownAttendance),
    ('A reason of 1-2000 characters', AdminFailure.invalidReason),
    ('Attendance must be closed', AdminFailure.notClosed),
    ('Proposed', AdminFailure.invalidTimes),
    ('No change was requested', AdminFailure.noChange),
    ('A pending correction already exists', AdminFailure.pendingCorrection),
    ('Attendance changed', AdminFailure.attendanceChanged),
  ];

  /// Maps an `employee-accounts` error answer.
  @visibleForTesting
  static AdminFailure accountFailureFor(int status, String? code) {
    return switch (code) {
      'forbidden' || 'unauthorized' => AdminFailure.notAllowed,
      'account_conflict' => AdminFailure.accountConflict,
      'invalid_input' => AdminFailure.invalidInput,
      'outcome_unknown' ||
      'account_service_unavailable' => AdminFailure.outcomeUnknown,
      _ when status == 429 => AdminFailure.tooManyRequests,
      _ when status == 404 => AdminFailure.serviceUnavailable,
      _ when status >= 500 => AdminFailure.outcomeUnknown,
      _ => AdminFailure.unknown,
    };
  }
}
