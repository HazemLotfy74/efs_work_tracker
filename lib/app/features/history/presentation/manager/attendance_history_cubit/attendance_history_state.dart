part of 'attendance_history_cubit.dart';

sealed class AttendanceHistoryState {
  const AttendanceHistoryState();
}

final class AttendanceHistoryLoading extends AttendanceHistoryState {
  const AttendanceHistoryLoading();
}

final class AttendanceHistoryLoaded extends AttendanceHistoryState {
  const AttendanceHistoryLoaded(this.sessions, {this.stale = false});
  final bool stale;

  /// Newest first; empty before the first check-in.
  final List<AttendanceSessionEntity> sessions;
}

final class AttendanceHistoryError extends AttendanceHistoryState {
  const AttendanceHistoryError();
}
