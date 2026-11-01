import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../domain/entities/employee_entity.dart';
import '../../../domain/repositories/admin_repository.dart';

part 'attendance_day_state.dart';

/// One attendance day for an admin: times, evidence and corrections.
/// Photos are signed one at a time, only when shown.
class AttendanceDayCubit extends Cubit<AttendanceDayState> {
  AttendanceDayCubit(this._repository, this.attendanceId)
    : super(const AttendanceDayLoading());

  final AdminRepository _repository;
  final String attendanceId;

  Future<void> load() async {
    emit(const AttendanceDayLoading());
    try {
      final day = await _repository.getDay(attendanceId);
      if (day == null) {
        if (!isClosed) emit(const AttendanceDayNotFound());
        return;
      }
      final employee = await _repository.getEmployee(day.employeeId);
      final corrections = await _repository.getCorrections(day.employeeId);
      if (isClosed) return;
      emit(
        AttendanceDayLoaded(
          day: day,
          employee: employee,
          corrections: [
            for (final request in corrections)
              if (request.attendanceId == attendanceId) request,
          ],
        ),
      );
    } catch (_) {
      if (!isClosed) emit(const AttendanceDayError());
    }
  }

  /// A short-lived link to a selfie; throws an `AdminFailure`.
  Future<String> evidenceUrl(String selfiePath) =>
      _repository.evidenceUrl(selfiePath);
}
