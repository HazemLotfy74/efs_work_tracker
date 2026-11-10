import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/admin_errors.dart';
import '../../../../../../core/errors/correction_errors.dart';
import '../../../../attendance_correction/domain/correction_rules.dart';
import '../../../domain/entities/employee_entity.dart';
import '../../../domain/repositories/admin_repository.dart';

part 'edit_attendance_state.dart';

/// An admin correcting the check-in / check-out of one closed day.
///
/// Checked with the same rules as employee corrections (CorrectionRules)
/// before sending; `admin_correct_attendance` checks them again and the
/// admin role. Nothing is changed until [save] succeeds.
class EditAttendanceCubit extends Cubit<EditAttendanceState> {
  EditAttendanceCubit(this._repository, this.attendanceId)
    : super(const EditAttendanceLoading());

  final AdminRepository _repository;
  final String attendanceId;

  Future<void> load() async {
    emit(const EditAttendanceLoading());
    try {
      final day = await _repository.getDay(attendanceId);
      if (day == null) {
        if (!isClosed) emit(const EditAttendanceNotFound());
        return;
      }
      final employee = await _repository.getEmployee(day.employeeId);
      if (!isClosed) emit(EditAttendanceReady(day: day, employee: employee));
    } catch (_) {
      if (!isClosed) emit(const EditAttendanceError());
    }
  }

  /// The reason to refuse these values before sending, or `null`.
  AdminFailure? check({
    required DateTime? checkIn,
    required DateTime? checkOut,
    required String reason,
  }) {
    final current = state;
    if (current is! EditAttendanceReady) return AdminFailure.busy;
    final invalid = CorrectionRules.check(
      current.day.session,
      checkIn: checkIn,
      checkOut: checkOut,
      reason: reason,
    );
    return switch (invalid) {
      null => null,
      CorrectionFailure.invalidReason => AdminFailure.invalidReason,
      CorrectionFailure.notClosed => AdminFailure.notClosed,
      _ => AdminFailure.invalidTimes,
    };
  }

  /// Sends the correction; [EditAttendanceSaved] on success.
  Future<void> save({
    required DateTime? checkIn,
    required DateTime? checkOut,
    required String reason,
  }) async {
    final current = state;
    if (current is! EditAttendanceReady || current.saving) return;
    final invalid = check(checkIn: checkIn, checkOut: checkOut, reason: reason);
    if (invalid != null) {
      emit(current.copyWith(failure: () => invalid));
      return;
    }
    emit(current.copyWith(saving: true, failure: () => null));
    try {
      await _repository.correctAttendance(
        attendanceId,
        checkIn: checkIn!,
        checkOut: checkOut!,
        reason: reason,
      );
      if (!isClosed) emit(const EditAttendanceSaved());
    } catch (error) {
      if (isClosed) return;
      emit(
        current.copyWith(
          saving: false,
          failure: () => error is AdminFailure ? error : AdminFailure.unknown,
        ),
      );
    }
  }
}
