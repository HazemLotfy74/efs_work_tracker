import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../domain/repositories/admin_repository.dart';

part 'employee_history_state.dart';

/// One employee's attendance days, for an administrator.
class EmployeeHistoryCubit extends Cubit<EmployeeHistoryState> {
  EmployeeHistoryCubit(this._repository, this.employeeId)
    : super(const EmployeeHistoryLoading());

  final AdminRepository _repository;
  final String employeeId;

  /// Only the newest load may emit.
  int _loadId = 0;

  Future<void> load() async {
    final loadId = ++_loadId;
    if (state is! EmployeeHistoryLoaded) emit(const EmployeeHistoryLoading());
    try {
      final sessions = await _repository.getHistory(employeeId);
      if (isClosed || loadId != _loadId) return;
      emit(EmployeeHistoryLoaded(sessions));
    } catch (_) {
      if (isClosed || loadId != _loadId) return;
      if (state is! EmployeeHistoryLoaded) emit(const EmployeeHistoryError());
    }
  }
}
