// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ar locale. All the
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
  String get localeName => 'ar';

  static String m0(count) =>
      "${Intl.plural(count, zero: 'لا ساعات', one: 'ساعة واحدة', two: 'ساعتان', few: '${count} ساعات', many: '${count} ساعة', other: '${count} ساعة')}";

  static String m1(start, end) => "مواعيد العمل الرسمية · ${start}–${end}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Alerts": MessageLookupByLibrary.simpleMessage("الاشعارات"),
    "GoodMorning": MessageLookupByLibrary.simpleMessage(""),
    "History": MessageLookupByLibrary.simpleMessage("التواريخ"),
    "Home": MessageLookupByLibrary.simpleMessage("الرئيسية"),
    "Profile": MessageLookupByLibrary.simpleMessage("ملفك الشخصي"),
    "checkInNow": MessageLookupByLibrary.simpleMessage("سجّل الحضور الآن"),
    "currentLocalTime": MessageLookupByLibrary.simpleMessage(
      "الوقت المحلي الحالي",
    ),
    "hoursCount": m0,
    "notCheckedIn": MessageLookupByLibrary.simpleMessage("لم يتم تسجيل الحضور"),
    "officialShift": m1,
  };
}
