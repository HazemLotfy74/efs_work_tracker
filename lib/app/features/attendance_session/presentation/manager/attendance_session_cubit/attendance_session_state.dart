part of 'attendance_session_cubit.dart';

sealed class AttendanceSessionState {
  const AttendanceSessionState();
}

final class AttendanceSessionLoading extends AttendanceSessionState {
  const AttendanceSessionLoading();
}

final class AttendanceSessionLoaded extends AttendanceSessionState {
  const AttendanceSessionLoaded({required this.shift, this.session});

  /// Today's shift; `null` when today is not a working day.
  final ShiftEntity? shift;

  /// Today's session; `null` when the user has not checked in yet.
  final AttendanceSessionEntity? session;

  /// Check-in is possible: a working day, no check-in yet, shift not over.
  bool canCheckInAt(DateTime now) {
    final shift = this.shift;
    return session == null && shift != null && !shift.hasEndedAt(now);
  }
}

final class AttendanceSessionError extends AttendanceSessionState {
  const AttendanceSessionError();
}
