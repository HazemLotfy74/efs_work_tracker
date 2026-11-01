part of 'edit_attendance_cubit.dart';

sealed class EditAttendanceState {
  const EditAttendanceState();
}

final class EditAttendanceLoading extends EditAttendanceState {
  const EditAttendanceLoading();
}

final class EditAttendanceNotFound extends EditAttendanceState {
  const EditAttendanceNotFound();
}

final class EditAttendanceError extends EditAttendanceState {
  const EditAttendanceError();
}

final class EditAttendanceReady extends EditAttendanceState {
  const EditAttendanceReady({
    required this.day,
    required this.employee,
    this.saving = false,
    this.failure,
  });

  final EmployeeDay day;
  final EmployeeEntity? employee;
  final bool saving;

  /// Why the last attempt was refused (by the form or the server).
  final AdminFailure? failure;

  EditAttendanceReady copyWith({
    bool? saving,
    AdminFailure? Function()? failure,
  }) => EditAttendanceReady(
    day: day,
    employee: employee,
    saving: saving ?? this.saving,
    failure: failure == null ? this.failure : failure(),
  );
}

final class EditAttendanceSaved extends EditAttendanceState {
  const EditAttendanceSaved();
}
