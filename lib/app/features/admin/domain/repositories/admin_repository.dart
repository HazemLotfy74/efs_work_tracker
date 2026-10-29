import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../entities/admin_request_entity.dart';
import '../entities/employee_entity.dart';

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

  /// Pending cash requests of other employees, oldest first.
  Future<List<AdminRequestEntity>> getPendingRequests();

  Future<void> review(
    AdminRequestEntity request, {
    required bool approve,
    String? note,
  });
}
