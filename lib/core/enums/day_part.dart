import '../../l10n/app_localizations.dart';

/// Part of the day, used for greetings like "Good Morning".
enum DayPart {
  morning,
  afternoon,
  evening;

  /// Morning 5:00–11:59, afternoon 12:00–16:59, evening the rest.
  static DayPart of(DateTime time) {
    final hour = time.toLocal().hour;
    if (hour >= 5 && hour < 12) return DayPart.morning;
    if (hour >= 12 && hour < 17) return DayPart.afternoon;
    return DayPart.evening;
  }

  String greeting(AppLocalizations l10n) {
    return switch (this) {
      DayPart.morning => l10n.goodMorning,
      DayPart.afternoon => l10n.goodAfternoon,
      DayPart.evening => l10n.goodEvening,
    };
  }
}
