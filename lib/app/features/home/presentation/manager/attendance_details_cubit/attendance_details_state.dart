part of 'attendance_details_cubit.dart';

sealed class AttendanceDetailsState {
  const AttendanceDetailsState();
}

final class AttendanceDetailsLoading extends AttendanceDetailsState {
  const AttendanceDetailsLoading();
}

final class AttendanceDetailsLoaded extends AttendanceDetailsState {
  const AttendanceDetailsLoaded(this.session);
  final AttendanceSessionEntity session;
}

/// No such record for this employee (wrong id, or another employee's).
final class AttendanceDetailsNotFound extends AttendanceDetailsState {
  const AttendanceDetailsNotFound();
}

final class AttendanceDetailsError extends AttendanceDetailsState {
  const AttendanceDetailsError();
}
