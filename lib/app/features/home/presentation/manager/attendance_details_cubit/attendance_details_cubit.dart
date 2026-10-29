import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../../attendance_session/domain/repositories/attendance_repository.dart';

part 'attendance_details_state.dart';

/// One attendance day of the signed-in employee, for its details page.
class AttendanceDetailsCubit extends Cubit<AttendanceDetailsState> {
  AttendanceDetailsCubit(this._repository, this.id)
    : super(const AttendanceDetailsLoading());

  final AttendanceRepository _repository;
  final String id;

  Future<void> load() async {
    emit(const AttendanceDetailsLoading());
    try {
      final session = await _repository.getSession(id);
      if (isClosed) return;
      emit(
        session == null
            ? const AttendanceDetailsNotFound()
            : AttendanceDetailsLoaded(session),
      );
    } catch (_) {
      if (!isClosed) emit(const AttendanceDetailsError());
    }
  }
}
