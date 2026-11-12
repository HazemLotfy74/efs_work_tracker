import '../../../auth/domain/entities/user_entity.dart';

/// What an account may do beyond self-service, as codes.
///
/// The live database decides it two ways: the admin role (every admin-area
/// code in [all]), and the per-employee `can_review_*` flags
/// ([delegable]). The finer codes exist so each screen and button asks one
/// question; the unapplied 20261111090000_permissions.sql is NOT used.
///
/// Everyday self-service (own attendance, check-in/out, own corrections and
/// cash requests) needs no code: every active account has it.
abstract final class Permission {
  static const attendanceViewAll = 'attendance.view_all';
  static const correctionsView = 'attendance.view_correction_requests';
  static const correctionsApprove = 'attendance.approve_correction';
  static const correctionsReject = 'attendance.reject_correction';
  static const attendanceEdit = 'attendance.edit';
  static const scheduleEdit = 'attendance.edit_schedule';
  static const cashViewAll = 'cash.view_all';
  static const cashApprove = 'cash.approve';
  static const cashReject = 'cash.reject';
  static const employeesView = 'employees.view';
  static const employeesEdit = 'employees.edit';
  static const managePermissions = 'employees.manage_permissions';
  static const reportsView = 'reports.view';
  static const reportsExport = 'reports.export';
  static const auditView = 'audit.view';

  // What the live database lets an admin give an employee: the
  // `profiles.can_review_*` flags. Each lets the employee approve or reject
  // only the requests an admin assigns to them (`assigned_reviewer_id`),
  // through `review_assigned_*`. Admins don't hold them: they review
  // through `review_request`.
  static const reviewAssignedCash = 'review.expense_advances';
  static const reviewAssignedCorrections = 'review.attendance_corrections';
  static const reviewAssignedOvertime = 'review.overtime';

  /// The codes an employee can be given individually, with the `profiles`
  /// column and the admin function behind each.
  static const delegable = {
    reviewAssignedCash: (
      column: 'can_review_expense_advances',
      function: 'admin_set_expense_advance_reviewer_permission',
      category: 'cash',
    ),
    reviewAssignedCorrections: (
      column: 'can_review_attendance_corrections',
      function: 'admin_set_attendance_correction_reviewer_permission',
      category: 'attendance',
    ),
    reviewAssignedOvertime: (
      column: 'can_review_overtime',
      function: 'admin_set_overtime_reviewer_permission',
      category: 'attendance',
    ),
  };

  /// Every admin-area code; the admin role holds them all.
  static const all = [
    attendanceViewAll,
    correctionsView,
    correctionsApprove,
    correctionsReject,
    attendanceEdit,
    scheduleEdit,
    cashViewAll,
    cashApprove,
    cashReject,
    employeesView,
    employeesEdit,
    managePermissions,
    reportsView,
    reportsExport,
    auditView,
  ];
}

/// What the signed-in account may do beyond self-service. Only decides what
/// the app shows: the database checks every code again on every request.
class PermissionSet {
  const PermissionSet(this.codes, {this.isAdmin = false});

  /// Before the permissions migration: admins hold every code, employees
  /// none (exactly what the database's admin role checks allow).
  factory PermissionSet.fromRole(UserEntity? user) => user == null
      ? none
      : user.isAdmin
      ? PermissionSet(Permission.all.toSet(), isAdmin: true)
      : const PermissionSet({});

  static const none = PermissionSet({});

  final Set<String> codes;

  /// The account's role is admin. Account creation stays role-based (the
  /// `employee-accounts` function checks the role, not a code).
  final bool isAdmin;

  bool can(String code) => codes.contains(code);

  bool canAny(Iterable<String> some) => some.any(codes.contains);

  /// Anything that opens the admin area. A delegated reviewer has their own
  /// screen instead: the database shows them only what is assigned to them.
  bool get hasAdminArea =>
      isAdmin || codes.any((code) => !Permission.delegable.containsKey(code));

  /// Can decide requests an admin assigns to them (the app has no overtime
  /// requests, so that flag alone opens nothing).
  bool get hasAssignedReviews =>
      can(Permission.reviewAssignedCash) ||
      can(Permission.reviewAssignedCorrections);

  @override
  bool operator ==(Object other) =>
      other is PermissionSet &&
      other.isAdmin == isAdmin &&
      other.codes.length == codes.length &&
      other.codes.containsAll(codes);

  @override
  int get hashCode => Object.hash(isAdmin, Object.hashAllUnordered(codes));
}

/// One code as it applies to an employee, for the management screen.
class PermissionEntry {
  const PermissionEntry({
    required this.code,
    required this.category,
    required this.sensitive,
    required this.fromRole,
    required this.granted,
    required this.canChange,
    this.grantedBy,
    this.grantedAt,
  });

  final String code;

  /// `attendance`, `cash`, `employees` or `reports`.
  final String category;

  /// Only a role admin may grant it.
  final bool sensitive;

  /// Held through the account's role (can't be removed per person).
  final bool fromRole;

  /// Granted individually.
  final bool granted;

  /// The signed-in manager may grant or remove it.
  final bool canChange;
  final String? grantedBy;
  final DateTime? grantedAt;

  bool get effective => fromRole || granted;
}
