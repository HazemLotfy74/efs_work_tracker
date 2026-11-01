import '../../../attendance_session/domain/entities/attendance_session_entity.dart';

/// Something on an attendance day an admin should look at.
enum AttendanceFlag {
  /// Checked in after the start plus the grace period (`late_minutes`).
  late,

  /// Checked out before the shift end of the day's own schedule.
  leftEarly,

  /// Closed automatically without a check-out; hours not confirmed.
  missingCheckOut,

  /// Times changed by an approved correction (`has_correction`).
  corrected;

  /// Every record starts with a check-in (the server creates it then), so
  /// "missing check-in" can't occur in this database.
  static Set<AttendanceFlag> of(AttendanceSessionEntity day, DateTime now) => {
    if (day.lateMinutes > 0) late,
    if (day.leftEarly) leftEarly,
    if (day.statusAt(now) == AttendanceDayStatus.needsReview) missingCheckOut,
    if (day.hasCorrection) corrected,
  };

  /// Flags that need an admin's attention (a correction is already done).
  bool get needsAttention => this != corrected;
}

/// An inclusive range of work dates (date only).
class WorkDateRange {
  WorkDateRange(DateTime from, DateTime to)
    : from = DateTime(from.year, from.month, from.day),
      to = DateTime(to.year, to.month, to.day);

  final DateTime from;
  final DateTime to;

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  @override
  bool operator ==(Object other) =>
      other is WorkDateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Totals for an employee over a set of days, from the records and their
/// schedules only. Hours count only when confirmed (checked out, or
/// corrected), as everywhere else in the app.
class EmployeeAttendanceStats {
  const EmployeeAttendanceStats({
    required this.days,
    required this.worked,
    required this.overtime,
    required this.late,
    required this.leftEarly,
    required this.missingCheckOut,
    required this.corrected,
    required this.needsAttention,
  });

  factory EmployeeAttendanceStats.of(
    Iterable<AttendanceSessionEntity> sessions,
    DateTime now,
  ) {
    var days = 0, late = 0, early = 0, missing = 0, corrected = 0, review = 0;
    var worked = Duration.zero, overtime = Duration.zero;
    for (final day in sessions) {
      days++;
      final flags = AttendanceFlag.of(day, now);
      if (flags.contains(AttendanceFlag.late)) late++;
      if (flags.contains(AttendanceFlag.leftEarly)) early++;
      if (flags.contains(AttendanceFlag.missingCheckOut)) missing++;
      if (flags.contains(AttendanceFlag.corrected)) corrected++;
      if (flags.any((flag) => flag.needsAttention)) review++;
      final duration = day.verifiedDuration;
      if (duration != null) {
        worked += duration.worked;
        overtime += duration.overtime;
      }
    }
    return EmployeeAttendanceStats(
      days: days,
      worked: worked,
      overtime: overtime,
      late: late,
      leftEarly: early,
      missingCheckOut: missing,
      corrected: corrected,
      needsAttention: review,
    );
  }

  final int days;

  /// Confirmed worked time; unconfirmed days add nothing.
  final Duration worked;

  /// Worked time beyond 8 hours on confirmed days.
  final Duration overtime;
  final int late;
  final int leftEarly;
  final int missingCheckOut;
  final int corrected;

  /// Days with at least one flag other than "corrected".
  final int needsAttention;
}
