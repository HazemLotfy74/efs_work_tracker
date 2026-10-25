part of 'attendance_session_cubit.dart';

sealed class AttendanceSessionState {
  const AttendanceSessionState();
}

final class AttendanceSessionLoading extends AttendanceSessionState {
  const AttendanceSessionLoading();
}

final class AttendanceSessionLoaded extends AttendanceSessionState {
  const AttendanceSessionLoaded({required this.shift, this.session});

  final ShiftEntity shift;

  /// Today's session; `null` when the user has not checked in yet.
  final AttendanceSessionEntity? session;
}

final class AttendanceSessionError extends AttendanceSessionState {
  const AttendanceSessionError();
}
