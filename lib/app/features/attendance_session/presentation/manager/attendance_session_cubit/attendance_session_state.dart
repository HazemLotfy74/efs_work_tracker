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

  /// Whether check-in is possible at [now], by the same rule the server's
  /// `check_in` applies: a working day, no check-in yet, from the shift
  /// start until the shift end. The server checks again with its own clock,
  /// so a wrong phone clock can only show the wrong state, never record a
  /// wrong time.
  CheckInAvailability checkInAt(DateTime now) {
    final shift = this.shift;
    if (session != null) return CheckInAvailability.alreadyCheckedIn;
    if (shift == null) return CheckInAvailability.notWorkingDay;
    if (shift.isBeforeStartAt(now)) return CheckInAvailability.notYetOpen;
    if (shift.hasEndedAt(now)) return CheckInAvailability.closed;
    return CheckInAvailability.open;
  }

  bool canCheckInAt(DateTime now) => checkInAt(now) == CheckInAvailability.open;
}

enum CheckInAvailability {
  open,

  /// Before the window opens (today's shift start).
  notYetOpen,

  /// After the window closes (today's shift end).
  closed,
  notWorkingDay,
  alreadyCheckedIn,
}

final class AttendanceSessionError extends AttendanceSessionState {
  const AttendanceSessionError();
}
