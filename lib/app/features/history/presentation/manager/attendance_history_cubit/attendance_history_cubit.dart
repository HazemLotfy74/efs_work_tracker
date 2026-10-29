import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../../attendance_session/domain/repositories/attendance_repository.dart';

part 'attendance_history_state.dart';

/// The signed-in employee's past attendance days, for the History tab.
class AttendanceHistoryCubit extends Cubit<AttendanceHistoryState> {
  AttendanceHistoryCubit(this._repository)
    : super(const AttendanceHistoryLoading());

  final AttendanceRepository _repository;

  /// Only the newest load may emit.
  int _loadId = 0;

  /// Loads the days; a failed refresh keeps the list that is shown.
  Future<void> load() async {
    final loadId = ++_loadId;
    if (state is! AttendanceHistoryLoaded) {
      emit(const AttendanceHistoryLoading());
    }
    try {
      final sessions = await _repository.getHistory();
      if (isClosed || loadId != _loadId) return;
      emit(AttendanceHistoryLoaded(sessions));
    } catch (_) {
      if (isClosed || loadId != _loadId) return;
      if (state is! AttendanceHistoryLoaded) {
        emit(const AttendanceHistoryError());
      }
    }
  }
}
