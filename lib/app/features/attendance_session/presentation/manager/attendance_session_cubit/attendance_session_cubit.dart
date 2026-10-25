import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/attendance_event_entity.dart';
import '../../../domain/entities/attendance_session_entity.dart';
import '../../../domain/entities/attendance_type.dart';
import '../../../domain/entities/shift_entity.dart';
import '../../../domain/repositories/attendance_repository.dart';

part 'attendance_session_state.dart';

/// Today's attendance for the whole app: the shift and the session.
///
/// Provided once in main.dart, so Home, the check-in/out flow and the
/// success screens all see the same session.
class AttendanceSessionCubit extends Cubit<AttendanceSessionState> {
  AttendanceSessionCubit(this._repository)
    : super(const AttendanceSessionLoading());

  final AttendanceRepository _repository;

  Future<void> load() async {
    emit(const AttendanceSessionLoading());
    try {
      final shift = await _repository.getShift();
      final session = await _repository.getTodaySession();
      if (isClosed) return;
      emit(AttendanceSessionLoaded(shift: shift, session: session));
    } catch (_) {
      if (!isClosed) emit(const AttendanceSessionError());
    }
  }

  /// Saves a finished check-in or check-out flow.
  ///
  /// Throws when saving fails, so the Review step can show the error and the
  /// user can try again without losing what they captured.
  Future<void> record(AttendanceEventEntity event) async {
    final current = state;
    if (current is! AttendanceSessionLoaded) {
      throw StateError('Attendance is not loaded.');
    }

    final session = switch (event.type) {
      AttendanceType.checkIn => await _repository.checkIn(event),
      AttendanceType.checkOut => await _repository.checkOut(
        current.session ?? (throw StateError('Not checked in.')),
        event,
      ),
    };
    if (!isClosed) {
      emit(AttendanceSessionLoaded(shift: current.shift, session: session));
    }
  }
}
