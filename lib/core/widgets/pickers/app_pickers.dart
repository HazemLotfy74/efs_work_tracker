import 'package:flutter/material.dart';

/// The app's date and time pickers. Colors, shapes and type come from
/// `AppTheme` (`datePickerTheme`, `timePickerTheme`); the language and text
/// direction from the app locale (Arabic pickers are right to left); the
/// 12/24-hour clock from the phone's setting.

/// One day between [firstDate] and [lastDate], or `null` when cancelled.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) {
  DateTime day(DateTime value) => DateTime(value.year, value.month, value.day);
  final first = day(firstDate);
  final last = day(lastDate);
  var initial = day(initialDate);
  if (initial.isBefore(first)) initial = first;
  if (initial.isAfter(last)) initial = last;
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    helpText: helpText,
    initialEntryMode: DatePickerEntryMode.calendarOnly,
  );
}

/// A range of days, or `null` when cancelled.
Future<DateTimeRange?> showAppDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialRange,
  required DateTime firstDate,
  required DateTime lastDate,
}) => showDateRangePicker(
  context: context,
  initialDateRange: initialRange,
  firstDate: firstDate,
  lastDate: lastDate,
  initialEntryMode: DatePickerEntryMode.calendarOnly,
);

/// A time of day, or `null` when cancelled.
Future<TimeOfDay?> showAppTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  String? helpText,
}) => showTimePicker(
  context: context,
  initialTime: initialTime,
  helpText: helpText,
  initialEntryMode: TimePickerEntryMode.dial,
  builder: (context, child) => MediaQuery(
    // Follow the phone's 12/24-hour setting, as every time label does.
    data: MediaQuery.of(context).copyWith(
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    ),
    child: child!,
  ),
);
