part of 'attendance_day_cubit.dart';

sealed class AttendanceDayState {
  const AttendanceDayState();
}

final class AttendanceDayLoading extends AttendanceDayState {
  const AttendanceDayLoading();
}

final class AttendanceDayNotFound extends AttendanceDayState {
  const AttendanceDayNotFound();
}

final class AttendanceDayError extends AttendanceDayState {
  const AttendanceDayError();
}

final class AttendanceDayLoaded extends AttendanceDayState {
  const AttendanceDayLoaded({
    required this.day,
    required this.employee,
    required this.corrections,
  });

  final EmployeeDay day;

  /// `null` if the profile can't be read any more.
  final EmployeeEntity? employee;

  /// Correction requests for this day, newest first.
  final List<CorrectionRequestEntity> corrections;
}
