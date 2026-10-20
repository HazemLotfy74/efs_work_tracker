// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(count) =>
      "${Intl.plural(count, one: '1 hour', other: '${count} hours')}";

  static String m1(start, end) => "Official shift · ${start}–${end}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Alerts": MessageLookupByLibrary.simpleMessage("Alerts"),
    "ApprovedOT": MessageLookupByLibrary.simpleMessage("Approved OT"),
    "Attendance": MessageLookupByLibrary.simpleMessage("Attendance"),
    "EarlyLeave": MessageLookupByLibrary.simpleMessage("Early Leave"),
    "GoodMorning": MessageLookupByLibrary.simpleMessage("Good Morning"),
    "History": MessageLookupByLibrary.simpleMessage("History"),
    "Home": MessageLookupByLibrary.simpleMessage("Home"),
    "LastMonth": MessageLookupByLibrary.simpleMessage("Last Month"),
    "LastWeek": MessageLookupByLibrary.simpleMessage("Last Week"),
    "LastYear": MessageLookupByLibrary.simpleMessage("Last Year"),
    "Lateness": MessageLookupByLibrary.simpleMessage("Lateness"),
    "Profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "Recorded": MessageLookupByLibrary.simpleMessage("Recorded"),
    "Settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "ThisMonth": MessageLookupByLibrary.simpleMessage("This Month"),
    "ThisWeek": MessageLookupByLibrary.simpleMessage("This Week"),
    "ThisYear": MessageLookupByLibrary.simpleMessage("This Year"),
    "Today": MessageLookupByLibrary.simpleMessage("Today"),
    "TodayAttendance": MessageLookupByLibrary.simpleMessage(
      "Today\'s Attendance",
    ),
    "TodayOverview": MessageLookupByLibrary.simpleMessage("Today\'s Overview"),
    "ViewDetails": MessageLookupByLibrary.simpleMessage("View Details"),
    "Yesterday": MessageLookupByLibrary.simpleMessage("Yesterday"),
    "checkInNow": MessageLookupByLibrary.simpleMessage("Check In Now"),
    "currentLocalTime": MessageLookupByLibrary.simpleMessage(
      "Current Local Time",
    ),
    "hoursCount": m0,
    "notCheckedIn": MessageLookupByLibrary.simpleMessage("Not Checked In"),
    "officialShift": m1,
  };
}
