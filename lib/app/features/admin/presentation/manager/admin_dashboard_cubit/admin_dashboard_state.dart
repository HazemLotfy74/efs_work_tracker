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
  const AdminDashboardLoaded(
    this.rows, {
    this.earlyDepartures = const [],
    this.stale = false,
  });

  /// By employee name.
  final List<EmployeeToday> rows;

  /// Recent days (any date) on which someone checked out before their
  /// shift ended, newest first. `today` is that day, not necessarily today.
  final List<EmployeeToday> earlyDepartures;

  /// The last refresh failed; [rows] are from an earlier load.
  final bool stale;
}

final class AdminDashboardError extends AdminDashboardState {
  const AdminDashboardError();
}
