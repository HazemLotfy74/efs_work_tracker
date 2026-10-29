part of 'employee_history_cubit.dart';

sealed class EmployeeHistoryState {
  const EmployeeHistoryState();
}

final class EmployeeHistoryLoading extends EmployeeHistoryState {
  const EmployeeHistoryLoading();
}

final class EmployeeHistoryLoaded extends EmployeeHistoryState {
  const EmployeeHistoryLoaded(this.sessions);

  /// Newest first.
  final List<AttendanceSessionEntity> sessions;
}

final class EmployeeHistoryError extends EmployeeHistoryState {
  const EmployeeHistoryError();
}
