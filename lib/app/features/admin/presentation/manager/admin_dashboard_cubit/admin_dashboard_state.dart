part of 'admin_dashboard_cubit.dart';

/// An employee and today's attendance day (`null` before check-in).
typedef EmployeeToday = ({
  EmployeeEntity employee,
  AttendanceSessionEntity? today,
});

sealed class AdminDashboardState {
  const AdminDashboardState();
}

final class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

final class AdminDashboardLoaded extends AdminDashboardState {
  const AdminDashboardLoaded(this.rows, {this.stale = false});

  /// By employee name.
  final List<EmployeeToday> rows;

  /// The last refresh failed; [rows] are from an earlier load.
  final bool stale;
}

final class AdminDashboardError extends AdminDashboardState {
  const AdminDashboardError();
}
