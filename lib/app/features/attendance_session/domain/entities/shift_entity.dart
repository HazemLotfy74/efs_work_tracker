/// The employee's official working hours, e.g. 8:00 AM – 4:00 PM.
class ShiftEntity {
  const ShiftEntity({
    required this.start,
    required this.end,
    this.startsAt,
    this.endsAt,
    this.graceMinutes = 0,
  });

  /// Wall-clock time in the company's timezone: `Duration(hours: 8)` is
  /// 8:00 AM. Used for display only.
  final Duration start;
  final Duration end;

  /// Today's start and end as exact instants, computed by the server in the
  /// company's timezone; `null` for [standard]. Use these for comparisons.
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Minutes after the start before a check-in counts as late.
  final int graceMinutes;

  /// Used until shifts come from the backend.
  static const standard = ShiftEntity(
    start: Duration(hours: 8),
    end: Duration(hours: 16),
  );

  /// The shift start on the same (local) day as [day].
  DateTime startOn(DateTime day) => _at(day, start);

  /// The shift end on the same (local) day as [day].
  DateTime endOn(DateTime day) => _at(day, end);

  /// `true` once today's shift has ended; the server then refuses check-in.
  bool hasEndedAt(DateTime now) {
    final endsAt = this.endsAt;
    return endsAt != null && !now.isBefore(endsAt);
  }

  static DateTime _at(DateTime day, Duration offset) {
    final local = day.toLocal();
    return DateTime(local.year, local.month, local.day).add(offset);
  }

  @override
  bool operator ==(Object other) =>
      other is ShiftEntity &&
      other.start == start &&
      other.end == end &&
      other.startsAt == startsAt &&
      other.endsAt == endsAt &&
      other.graceMinutes == graceMinutes;

  @override
  int get hashCode => Object.hash(start, end, startsAt, endsAt, graceMinutes);
}
