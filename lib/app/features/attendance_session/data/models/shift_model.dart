import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/shift_entity.dart';

/// [ShiftEntity] from the database, in the schedule's timezone.
class ShiftModel extends ShiftEntity {
  const ShiftModel({
    required super.start,
    required super.end,
    super.startsAt,
    super.endsAt,
    super.graceMinutes,
  });

  /// From a `schedule_days` row for [businessDate]. [json] has `starts_at`
  /// and `ends_at` as Postgres `time` text ("08:00:00"), wall-clock times in
  /// [location]. They become exact instants the way the database does it:
  /// `(work_date + starts_at) at time zone timezone`.
  factory ShiftModel.fromScheduleDay(
    Map<String, dynamic> json, {
    required tz.Location location,
    required DateTime businessDate,
    required int graceMinutes,
  }) {
    final start = parseTime(json['starts_at'] as String);
    final end = parseTime(json['ends_at'] as String);
    // Built from the wall-clock fields, not midnight + hours, so it stays
    // right on a daylight-saving change (Egypt changes at midnight).
    DateTime at(Duration time) => tz.TZDateTime(
      location,
      businessDate.year,
      businessDate.month,
      businessDate.day,
      time.inHours,
      time.inMinutes.remainder(60),
      time.inSeconds.remainder(60),
    ).toUtc();
    return ShiftModel(
      start: start,
      end: end,
      startsAt: at(start),
      endsAt: at(end),
      graceMinutes: graceMinutes,
    );
  }

  /// From the schedule copied onto an `attendance_records` row at check-in
  /// (`scheduled_start`, `scheduled_end`, `timezone`, `grace_minutes`), so a
  /// past day keeps the schedule it had.
  factory ShiftModel.fromRecord(Map<String, dynamic> json) {
    final location = locationNamed(json['timezone'] as String);
    final startsAt = DateTime.parse(json['scheduled_start'] as String);
    final endsAt = DateTime.parse(json['scheduled_end'] as String);
    Duration wallClock(DateTime instant) {
      final local = tz.TZDateTime.from(instant, location);
      return Duration(hours: local.hour, minutes: local.minute);
    }

    return ShiftModel(
      start: wallClock(startsAt),
      end: wallClock(endsAt),
      startsAt: startsAt,
      endsAt: endsAt,
      graceMinutes: (json['grace_minutes'] as num?)?.toInt() ?? 0,
    );
  }

  static bool _timezonesLoaded = false;

  /// An IANA timezone such as "Africa/Cairo". Throws if unknown.
  static tz.Location locationNamed(String name) {
    if (!_timezonesLoaded) {
      tz_data.initializeTimeZones();
      _timezonesLoaded = true;
    }
    return tz.getLocation(name);
  }

  /// Postgres `time` as text, e.g. "08:00:00".
  static Duration parseTime(String value) {
    final parts = value.split(':').map(int.parse).toList();
    return Duration(
      hours: parts[0],
      minutes: parts.length > 1 ? parts[1] : 0,
      seconds: parts.length > 2 ? parts[2] : 0,
    );
  }
}
