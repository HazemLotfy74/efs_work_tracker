import 'package:timezone/timezone.dart' as tz;

import '../../../../core/errors/correction_errors.dart';
import '../../attendance_session/data/models/shift_model.dart';
import '../../attendance_session/domain/entities/attendance_session_entity.dart';

/// The rules `request_attendance_correction` checks, so the form can
/// explain a problem before sending. The server still decides.
abstract final class CorrectionRules {
  /// Longest reason or review note the database accepts.
  static const maxTextLength = 2000;

  /// Why [session] can't be corrected to these times, or `null` if it can.
  static CorrectionFailure? check(
    AttendanceSessionEntity session, {
    required DateTime? checkIn,
    required DateTime? checkOut,
    required String reason,
  }) {
    final text = reason.trim();
    if (text.isEmpty || text.length > maxTextLength) {
      return CorrectionFailure.invalidReason;
    }
    if (session.checkOut == null && !session.isAutoClosed) {
      return CorrectionFailure.notClosed;
    }
    if (checkIn == null) return CorrectionFailure.invalidTimes;
    if (checkOut == null) return CorrectionFailure.missingCheckOut;

    final workDate = session.workDate;
    final checkInDate = wallClock(session.timezone, checkIn);
    if (workDate != null &&
        (checkInDate.year != workDate.year ||
            checkInDate.month != workDate.month ||
            checkInDate.day != workDate.day)) {
      return CorrectionFailure.invalidTimes;
    }
    if (!checkIn.isBefore(session.scheduledEnd)) {
      return CorrectionFailure.invalidTimes;
    }
    // Before the deadline, never at it: midnight belongs to the next day.
    if (checkOut.isBefore(checkIn) ||
        !checkOut.isBefore(session.closeDeadline)) {
      return CorrectionFailure.invalidTimes;
    }
    return null;
  }

  /// The instant at [time] (wall clock) on [session]'s work date, in the
  /// day's timezone.
  static DateTime onWorkDate(AttendanceSessionEntity session, Duration time) {
    final date = session.workDate ?? wallClock(null, session.checkInTime);
    final hour = time.inHours;
    final minute = time.inMinutes.remainder(60);
    final timezone = session.timezone;
    if (timezone == null) {
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
    return tz.TZDateTime(
      ShiftModel.locationNamed(timezone),
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    ).toUtc();
  }

  /// [instant] as a plain local [DateTime] holding the wall-clock time in
  /// [timezone] (the phone's when `null`), so the date and time formatters,
  /// which convert to local time, show the company's time.
  static DateTime wallClock(String? timezone, DateTime instant) {
    if (timezone == null) return instant.toLocal();
    final t = tz.TZDateTime.from(instant, ShiftModel.locationNamed(timezone));
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }

  /// The wall-clock time of day of [instant] in [timezone].
  static Duration timeOfDay(String? timezone, DateTime instant) {
    final local = wallClock(timezone, instant);
    return Duration(hours: local.hour, minutes: local.minute);
  }
}
