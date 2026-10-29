/// The duration rule: the first 8 hours from check-in are regular time,
/// anything beyond is overtime, counted automatically (no request). Not
/// tied to the clock (8:00 AM to 9:00 PM is 8 h regular + 5 h overtime) and
/// no breaks are deducted (the database records none).
class WorkDuration {
  WorkDuration(Duration worked)
    : worked = worked < Duration.zero ? Duration.zero : worked;

  static const regularLimit = Duration(hours: 8);

  /// From check-in to the end of the session.
  final Duration worked;

  Duration get regular => worked > regularLimit ? regularLimit : worked;

  Duration get overtime =>
      worked > regularLimit ? worked - regularLimit : Duration.zero;

  /// How much of the 8 regular hours is missing.
  Duration get shortfall =>
      worked < regularLimit ? regularLimit - worked : Duration.zero;

  @override
  bool operator ==(Object other) =>
      other is WorkDuration && other.worked == worked;

  @override
  int get hashCode => worked.hashCode;
}
