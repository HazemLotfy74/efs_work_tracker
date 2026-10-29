import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../domain/entities/employee_entity.dart';
import '../../../domain/repositories/admin_repository.dart';

part 'admin_dashboard_state.dart';

/// Every employee with today's attendance, for the admin dashboard.
/// Loaded on open and on pull-to-refresh; never polled.
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._repository) : super(const AdminDashboardLoading());

  final AdminRepository _repository;

  /// Only the newest load may emit.
  int _loadId = 0;

  /// A failed refresh keeps what is shown, marked as stale.
  Future<void> load() async {
    final loadId = ++_loadId;
    if (state is! AdminDashboardLoaded) emit(const AdminDashboardLoading());
    try {
      final employees = await _repository.getEmployees();
      final schedules = await _repository.getSchedules();
      final today = await _repository.getToday(employees, schedules);
      if (isClosed || loadId != _loadId) return;
      emit(
        AdminDashboardLoaded([
          for (final employee in employees)
            (employee: employee, today: today[employee.id]),
        ]),
      );
    } catch (_) {
      if (isClosed || loadId != _loadId) return;
      final current = state;
      emit(
        current is AdminDashboardLoaded
            ? AdminDashboardLoaded(current.rows, stale: true)
            : const AdminDashboardError(),
      );
    }
  }
}
