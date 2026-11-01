import '../../attendance_session/domain/entities/attendance_session_entity.dart';

enum AttendanceHistoryFilter { all, late, overtime, needsReview }

/// Monthly totals use confirmed durations only, never assumed auto-close hours.
class AttendanceHistorySummary {
  AttendanceHistorySummary(List<AttendanceSessionEntity> sessions)
    : days = sessions.length,
      worked = sessions.fold(
        Duration.zero,
        (total, day) => total + (day.verifiedDuration?.worked ?? Duration.zero),
      ),
      overtime = sessions.fold(
        Duration.zero,
        (total, day) =>
            total + (day.verifiedDuration?.overtime ?? Duration.zero),
      ),
      lateDays = sessions.where((day) => day.lateMinutes > 0).length,
      lateMinutes = sessions.fold(0, (total, day) => total + day.lateMinutes),
      overtimeDays = sessions
          .where(
            (day) =>
                (day.verifiedDuration?.overtime ?? Duration.zero) >
                Duration.zero,
          )
          .length;

  final int days;
  final Duration worked;
  final Duration overtime;
  final int lateDays;
  final int lateMinutes;
  final int overtimeDays;
}

extension AttendanceHistoryFilterMatch on AttendanceHistoryFilter {
  bool matches(AttendanceSessionEntity session, DateTime now) => switch (this) {
    AttendanceHistoryFilter.all => true,
    AttendanceHistoryFilter.late => session.lateMinutes > 0,
    AttendanceHistoryFilter.overtime =>
      (session.durationAt(now)?.overtime ?? Duration.zero) > Duration.zero,
    AttendanceHistoryFilter.needsReview =>
      session.statusAt(now) == AttendanceDayStatus.needsReview,
  };
}
