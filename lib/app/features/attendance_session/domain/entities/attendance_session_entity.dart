import 'attendance_event_entity.dart';
import 'shift_entity.dart';
import 'work_duration.dart';

enum AttendanceDayStatus {
  inProgress,

  /// Ended with confirmed hours.
  completed,

  /// Ended without confirmed hours; an admin has to review it.
  needsReview,
}

/// One working day: a check-in and, once the user leaves, a check-out.
///
/// The server keeps these apart, and so does this class:
/// - [scheduledEnd]: the end of the scheduled shift (4:00 PM). Check-in
///   closes then; lateness is measured from the shift start.
/// - [closeDeadline]: `auto_close_deadline`, midnight after the work date
///   under the default policy. The session runs until a check-out or this
///   deadline; the server closes it then and records no check-out after it.
/// - [autoClosedAt]: set when the server closed the day (at the deadline);
///   not an employee action, and no proof of the hours worked.
/// - [checkOutTime]: the employee's real check-out.
/// - [effectiveCheckIn] / [effectiveCheckOut]: times approved by an admin
///   through a correction request ([hasCorrection]).
///
/// Worked time is only known when it is verified ([isVerified]); a day the
/// server closed is [needsReview] and has no worked time until corrected.
class AttendanceSessionEntity {
  const AttendanceSessionEntity({
    required this.id,
    required this.checkIn,
    required this.shift,
    this.checkOut,
    this._scheduledEnd,
    this._closeDeadline,
    this.autoClosedAt,
    this.effectiveCheckIn,
    this.effectiveCheckOut,
    this.hasCorrection = false,
    this.lateMinutes = 0,
    this.workDate,
    this.timezone,
  });

  /// Backend id (Supabase row id later).
  final String id;
  final AttendanceEventEntity checkIn;

  /// `null` while the user is still working.
  final AttendanceEventEntity? checkOut;

  /// The shift for this day, saved with the session.
  final ShiftEntity shift;

  final DateTime? _scheduledEnd;
  final DateTime? _closeDeadline;

  /// `null` unless the server closed the day automatically.
  final DateTime? autoClosedAt;

  /// Times after an approved correction; `null` means the actual times.
  final DateTime? effectiveCheckIn;
  final DateTime? effectiveCheckOut;

  /// An admin approved a correction of the times.
  final bool hasCorrection;

  /// Calculated by the database from the schedule and grace period.
  final int lateMinutes;

  /// The work date in the company's timezone (date only).
  final DateTime? workDate;

  /// The IANA timezone the record was saved in, e.g. "Africa/Cairo";
  /// `null` for in-memory test data (the phone's timezone is used then).
  final String? timezone;

  DateTime get checkInTime => checkIn.time!;
  DateTime? get checkOutTime => checkOut?.time;

  DateTime get scheduledEnd => _scheduledEnd ?? shift.endOn(checkInTime);

  /// When the server closes a session still open; [scheduledEnd] when the
  /// record has no deadline (in-memory test data).
  DateTime get closeDeadline => _closeDeadline ?? scheduledEnd;

  bool get isAutoClosed => autoClosedAt != null;

  /// `true` from check-in until a check-out or an automatic close.
  bool get isActive => checkOut == null && !isAutoClosed;

  /// Like [isActive], but also `false` once [closeDeadline] has passed,
  /// even before the server's automatic close has run (every minute).
  bool isActiveAt(DateTime now) => isActive && now.isBefore(closeDeadline);

  /// Neither checked out nor closed automatically.
  bool get canCheckOut => checkOut == null && !isAutoClosed;

  bool get _hasApprovedTimes => hasCorrection && effectiveCheckOut != null;

  /// The worked time is confirmed: by the employee's own check-out, or by
  /// an admin-approved correction.
  bool get isVerified =>
      (checkOut != null && !isAutoClosed) || _hasApprovedTimes;

  /// Closed without a check-out and not corrected yet: the hours are not
  /// known and an admin has to review them.
  bool get needsReview =>
      isAutoClosed && checkOut == null && !_hasApprovedTimes;

  /// The confirmed worked time, or `null` when it isn't confirmed.
  WorkDuration? get verifiedDuration {
    if (!isVerified) return null;
    final start = effectiveCheckIn ?? checkInTime;
    final end = effectiveCheckOut ?? checkOutTime!;
    return WorkDuration(end.difference(start));
  }

  /// The worked time to show at [now]: live while the session runs, the
  /// verified time once it ended, `null` when unconfirmed.
  WorkDuration? durationAt(DateTime now) => isActiveAt(now)
      ? WorkDuration(now.difference(checkInTime))
      : verifiedDuration;

  /// Regular worked time, as [durationAt]; zero when unconfirmed.
  Duration workedDuration([DateTime? now]) =>
      durationAt(now ?? DateTime.now())?.worked ?? Duration.zero;

  /// How much of the 8 regular hours is missing at the check-out; zero
  /// while active or when unconfirmed.
  Duration get earlyLeave => verifiedDuration?.shortfall ?? Duration.zero;

  /// How much of the 8 regular hours would be missing checking out at
  /// [time].
  Duration earlyLeaveFor(DateTime time) =>
      WorkDuration(time.difference(checkInTime)).shortfall;

  /// The one status every screen shows for this day.
  AttendanceDayStatus statusAt(DateTime now) {
    if (isActiveAt(now)) return AttendanceDayStatus.inProgress;
    if (isVerified) return AttendanceDayStatus.completed;
    // Closed by the server, or due to be (its close runs every minute).
    return AttendanceDayStatus.needsReview;
  }

  /// The server closes the session before 8 hours pass for this check-in.
  bool get endsBeforeRegularHours =>
      checkInTime.add(WorkDuration.regularLimit).isAfter(closeDeadline);

  AttendanceSessionEntity copyWith({AttendanceEventEntity? checkOut}) {
    return AttendanceSessionEntity(
      id: id,
      checkIn: checkIn,
      shift: shift,
      checkOut: checkOut ?? this.checkOut,
      scheduledEnd: _scheduledEnd,
      closeDeadline: _closeDeadline,
      autoClosedAt: autoClosedAt,
      effectiveCheckIn: effectiveCheckIn,
      effectiveCheckOut: effectiveCheckOut,
      hasCorrection: hasCorrection,
      lateMinutes: lateMinutes,
      workDate: workDate,
      timezone: timezone,
    );
  }
}
