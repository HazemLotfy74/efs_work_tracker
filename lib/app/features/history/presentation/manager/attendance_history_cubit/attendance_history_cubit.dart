import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../domain/repositories/history_repository.dart';

part 'attendance_history_state.dart';

/// The signed-in employee's past attendance days, for the History tab.
class AttendanceHistoryCubit extends Cubit<AttendanceHistoryState> {
  AttendanceHistoryCubit(this._repository, {DateTime? initialMonth})
    : _month = _monthStart(initialMonth ?? DateTime.now()),
      super(const AttendanceHistoryLoading());

  final HistoryRepository _repository;
  DateTime _month;
  DateTime get month => _month;

  Future<void> selectMonth(DateTime value) async {
    final selected = DateTime(value.year, value.month);
    if (selected == month) return;
    _month = selected;
    emit(const AttendanceHistoryLoading());
    await load();
  }

  /// Only the newest load may emit.
  int _loadId = 0;

  /// Loads the days; a failed refresh keeps the list that is shown.
  Future<void> load() async {
    final loadId = ++_loadId;
    if (state is! AttendanceHistoryLoaded) {
      emit(const AttendanceHistoryLoading());
    }
    try {
      final sessions = await _repository.getMonth(month);
      if (isClosed || loadId != _loadId) return;
      emit(AttendanceHistoryLoaded(sessions));
    } catch (_) {
      if (isClosed || loadId != _loadId) return;
      if (state case AttendanceHistoryLoaded(:final sessions)) {
        emit(AttendanceHistoryLoaded(sessions, stale: true));
      } else {
        emit(const AttendanceHistoryError());
      }
    }
  }
}

DateTime _monthStart(DateTime date) => DateTime(date.year, date.month);
