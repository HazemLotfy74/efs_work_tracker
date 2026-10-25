/// The employee's official working hours, e.g. 8:00 AM – 4:00 PM.
class ShiftEntity {
  const ShiftEntity({required this.start, required this.end});

  /// Time after midnight: `Duration(hours: 8)` is 8:00 AM.
  final Duration start;
  final Duration end;

  /// Used until shifts come from the backend.
  static const standard = ShiftEntity(
    start: Duration(hours: 8),
    end: Duration(hours: 16),
  );

  /// The shift start on the same (local) day as [day].
  DateTime startOn(DateTime day) => _at(day, start);

  /// The shift end on the same (local) day as [day].
  DateTime endOn(DateTime day) => _at(day, end);

  /// How long before the shift end [checkOut] is; zero at or after it.
  Duration earlyLeaveFor(DateTime checkOut) {
    final early = endOn(checkOut).difference(checkOut);
    return early.isNegative ? Duration.zero : early;
  }

  static DateTime _at(DateTime day, Duration offset) {
    final local = day.toLocal();
    return DateTime(local.year, local.month, local.day).add(offset);
  }

  @override
  bool operator ==(Object other) =>
      other is ShiftEntity && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
