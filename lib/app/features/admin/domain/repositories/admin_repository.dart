import '../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../entities/audit_entry_entity.dart';
import '../entities/admin_request_entity.dart';
import '../entities/employee_entity.dart';

/// An employee's login email and the change waiting for their confirmation.
typedef LoginEmail = ({
  String email,
  String? pendingEmail,
  DateTime? expiresAt,
});

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

  /// `admin_correct_attendance`: sets the confirmed times of a closed day
  /// of another employee. The recorded times and evidence are kept; the
  /// change is stored as an approved correction with [reason], and audited.
  Future<void> correctAttendance(
    String attendanceId, {
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  });

  /// `admin_assign_schedule`: the schedule for future days. Days already
  /// recorded keep the schedule they were saved with.
  Future<void> assignSchedule(String employeeId, String scheduleId);

  /// `audit_logs` rows about this employee (their profile, attendance,
  /// requests and corrections), newest first, at most [limit].
  Future<List<AuditEntryEntity>> getAuditHistory(
    String employeeId, {
    int limit = 200,
  });

  /// `admin_edit_employee_profile`: an employee account's name, username
  /// and employee code (normalized and validated by the database).
  Future<void> editEmployee(
    String employeeId, {
    required String fullName,
    required String username,
    required String employeeCode,
  });

  /// `get_employee_login_email`: an employee's login email and any email
  /// change still waiting for them.
  Future<LoginEmail> getLoginEmail(String employeeId);

  /// `admin_request_employee_email_change`: lets the employee change their
  /// login email to [newEmail] within 24 hours (they confirm it
  /// themselves); `null` cancels the request. Never changes it directly.
  Future<void> requestEmailChange(String employeeId, String? newEmail);

  /// `admin_assign_expense_advance_reviewer`: asks an employee who holds
  /// the cash review permission to decide a pending request; `null`
  /// removes the assignment. Never the requester.
  Future<void> assignCashReviewer(String requestId, String? reviewerId);

  /// Pending cash requests of other employees, oldest first.
  Future<List<AdminRequestEntity>> getPendingRequests();

  Future<void> review(
    AdminRequestEntity request, {
    required bool approve,
    String? note,
  });
}
