import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../../core/errors/admin_errors.dart';
import '../../../../../core/services/accounts_function.dart';
import '../../../../../core/services/database_services.dart';
import '../../../attendance_session/data/models/attendance_session_model.dart';
import '../../../attendance_session/data/models/shift_model.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/admin_request_entity.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/repositories/admin_repository.dart';

/// [AdminRepository] on the existing database, unchanged: reads through
/// the admin RLS policies, reviews through `review_request`, and creates
/// accounts through the `employee-accounts` Edge Function.
class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository({
    required this._databaseServices,
    required this._accountsFunction,
    required this._currentUserId,
    this._now = DateTime.now,
    this.timeout = const Duration(seconds: 20),
    this.isWeb = kIsWeb,
  });

  /// Running in a web browser, where CORS applies.
  final bool isWeb;

  final DatabaseServices _databaseServices;
  final AccountsFunction _accountsFunction;
  final String? Function() _currentUserId;

  /// Only used to find today's work date; the database's clock decides.
  final DateTime Function() _now;
  final Duration timeout;

  static const _employeeColumns =
      'id, full_name, username, employee_code, role, is_active, '
      'must_change_password, schedule_id';

  static const recordColumns =
      'id, employee_id, work_date, timezone, scheduled_start, scheduled_end, '
      'grace_minutes, actual_checkin, actual_checkout, auto_closed, '
      'auto_closed_at, auto_close_policy, auto_close_deadline, '
      'effective_checkin, effective_checkout, has_correction, late_minutes, '
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
    return _parse('profiles', rows, (json) {
      return EmployeeEntity(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        username: json['username'] as String,
        employeeCode: json['employee_code'] as String,
        role: UserRole.fromName(json['role'] as String?),
        isActive: json['is_active'] == true,
        mustChangePassword: json['must_change_password'] != false,
        scheduleId: json['schedule_id'] as String,
      );
    });
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
          column: recordColumns,
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
  Future<List<AttendanceSessionEntity>> getHistory(
    String employeeId, {
    int limit = 60,
  }) async {
    _requireUser();
    final rows = await _guard(
      'attendance_records',
      () => _databaseServices.getData(
        path: 'attendance_records',
        column: recordColumns,
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
          'requested_amount, currency',
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

  /// Maps a database error from the admin reads and `review_request`.
  @visibleForTesting
  static AdminFailure failureFor(String? code, String message) {
    if (message.startsWith('You cannot review your own request')) {
      return AdminFailure.ownRequest;
    }
    if (message.startsWith('This request has already been reviewed')) {
      return AdminFailure.alreadyReviewed;
    }
    if (message.startsWith('Request not found')) return AdminFailure.notFound;
    return switch (code) {
      '42501' || 'PGRST301' || 'PGRST303' => AdminFailure.notAllowed,
      '22023' => AdminFailure.invalidInput,
      'PGRST202' || 'PGRST205' => AdminFailure.serviceUnavailable,
      _ => AdminFailure.unknown,
    };
  }

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
