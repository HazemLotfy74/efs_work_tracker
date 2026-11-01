import '../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../entities/audit_entry_entity.dart';
import '../entities/admin_request_entity.dart';
import '../entities/employee_entity.dart';

/// One attendance day and whose it is.
typedef EmployeeDay = ({String employeeId, AttendanceSessionEntity session});

/// What an administrator reads and does. Hiding admin screens is not the
/// security boundary: RLS, `require_actor(true)` and the
/// `employee-accounts` Edge Function check the role on every call.
///
/// Every method throws an `AdminFailure` (core/errors/admin_errors.dart).
abstract interface class AdminRepository {
  /// Every account, by name.
  Future<List<EmployeeEntity>> getEmployees();

  Future<List<WorkScheduleOption>> getSchedules();

  /// Each employee's attendance day for today's work date (in their
  /// schedule's timezone), by employee id. Employees without a record
  /// today are missing.
  Future<Map<String, AttendanceSessionEntity>> getToday(
    List<EmployeeEntity> employees,
    List<WorkScheduleOption> schedules,
  );

  /// Everyone's most recent attendance days, newest first, at most [limit].
  Future<List<EmployeeDay>> getRecentDays({int limit = 300});

  /// One employee's attendance days, newest first.
  Future<List<AttendanceSessionEntity>> getHistory(
    String employeeId, {
    int limit = 60,
  });

  /// Creates the account through the `employee-accounts` Edge Function and
  /// returns its id. Retrying with the same [requestId] and draft never
  /// creates a second account.
  Future<String> createEmployee(
    NewEmployeeDraft draft, {
    required String requestId,
  });

  /// One account, or `null` when there is none.
  Future<EmployeeEntity?> getEmployee(String id);

  /// One attendance day with its evidence events, or `null`.
  Future<EmployeeDay?> getDay(String attendanceId);

  /// An employee's correction requests (any status), newest first.
  Future<List<CorrectionRequestEntity>> getCorrections(String employeeId);

  /// A short-lived link to a check-in or check-out selfie. The bucket is
  /// private: Storage only signs it for an admin when the photo belongs to
  /// a recorded attendance event.
  Future<String> evidenceUrl(String selfiePath);

  /// `admin_set_employee_active`: employee accounts only, never yourself.
  Future<void> setEmployeeActive(String employeeId, {required bool active});

  /// `admin_assign_schedule`: the schedule for future days. Days already
  /// recorded keep the schedule they were saved with.
  Future<void> assignSchedule(String employeeId, String scheduleId);

  /// `audit_logs` rows about this employee (their profile, attendance,
  /// requests and corrections), newest first, at most [limit].
  Future<List<AuditEntryEntity>> getAuditHistory(
    String employeeId, {
    int limit = 200,
  });

  /// Pending cash requests of other employees, oldest first.
  Future<List<AdminRequestEntity>> getPendingRequests();

  Future<void> review(
    AdminRequestEntity request, {
    required bool approve,
    String? note,
  });
}
