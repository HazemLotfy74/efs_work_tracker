import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Localized date and time text for the UI. Use these instead of building
/// date strings by hand, so every screen shows dates the same way.
///
/// - The language comes from the app locale, so Arabic screens get Arabic
///   day and month names with no extra code.
/// - Every method converts to the phone's local time first, so it is safe to
///   pass the UTC times stored in entities.
/// - Times follow the phone's 12/24-hour setting.
///
/// ```dart
/// Text(checkIn.checkInTime!.formatTime(context))  // 8:07 AM
/// Text(now.formatLongDate(context))                // Wednesday, May 14
/// ```
extension DateTimeFormatX on DateTime {
  /// 8:07 AM, or 08:07 on a 24-hour phone.
  String formatTime(BuildContext context) {
    final locale = _locale(context);
    final format = _use24HourFormat(context)
        ? DateFormat.Hm(locale)
        : DateFormat.jm(locale);
    return format.format(toLocal());
  }

  /// 8:07 without AM/PM, for a big clock. 08:07 on a 24-hour phone.
  String formatClock(BuildContext context) {
    final pattern = _use24HourFormat(context) ? 'HH:mm' : 'h:mm';
    return DateFormat(pattern, _locale(context)).format(toLocal());
  }

  /// Wed
  String formatWeekdayShort(BuildContext context) =>
      DateFormat.E(_locale(context)).format(toLocal());

  /// Wednesday
  String formatWeekday(BuildContext context) =>
      DateFormat.EEEE(_locale(context)).format(toLocal());

  /// 14
  String formatDayOfMonth(BuildContext context) =>
      DateFormat.d(_locale(context)).format(toLocal());

  /// May 14
  String formatMonthDay(BuildContext context) =>
      DateFormat.MMMMd(_locale(context)).format(toLocal());

  /// May 2025
  String formatMonthYear(BuildContext context) =>
      DateFormat.yMMM(_locale(context)).format(toLocal());

  /// Wed, May 14
  String formatShortDate(BuildContext context) =>
      DateFormat.MMMEd(_locale(context)).format(toLocal());

  /// Wednesday, May 14
  String formatLongDate(BuildContext context) =>
      DateFormat.MMMMEEEEd(_locale(context)).format(toLocal());

  /// Wednesday, May 14, 2025
  String formatFullDate(BuildContext context) =>
      DateFormat.yMMMMEEEEd(_locale(context)).format(toLocal());

  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  static bool _use24HourFormat(BuildContext context) =>
      MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false;
}
