// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Not Checked In`
  String get notCheckedIn {
    return Intl.message(
      'Not Checked In',
      name: 'notCheckedIn',
      desc: 'Badge on the home attendance card when the user hasn\'t checked in today',
      args: [],
    );
  }

  /// `Current Local Time`
  String get currentLocalTime {
    return Intl.message(
      'Current Local Time',
      name: 'currentLocalTime',
      desc: '',
      args: [],
    );
  }

  /// `Check In Now`
  String get checkInNow {
    return Intl.message('Check In Now', name: 'checkInNow', desc: '', args: []);
  }

  /// `Official shift · {start}–{end}`
  String officialShift(String start, String end) {
    return Intl.message(
      'Official shift · $start–$end',
      name: 'officialShift',
      desc: 'Shift hours under the check-in button',
      args: [start, end],
    );
  }

  /// `{count, plural, =1{1 hour} other{{count} hours}}`
  String hoursCount(int count) {
    return Intl.plural(
      count,
      one: '1 hour',
      other: '$count hours',
      name: 'hoursCount',
      desc: '',
      args: [count],
    );
  }

  /// `Good Morning`
  String get GoodMorning {
    return Intl.message(
      'Good Morning',
      name: 'GoodMorning',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get Home {
    return Intl.message('Home', name: 'Home', desc: '', args: []);
  }

  /// `Attendance`
  String get Attendance {
    return Intl.message('Attendance', name: 'Attendance', desc: '', args: []);
  }

  /// `View Details`
  String get ViewDetails {
    return Intl.message(
      'View Details',
      name: 'ViewDetails',
      desc: '',
      args: [],
    );
  }

  /// `Today's Overview`
  String get TodayOverview {
    return Intl.message(
      'Today\'s Overview',
      name: 'TodayOverview',
      desc: '',
      args: [],
    );
  }

  /// `Recorded`
  String get Recorded {
    return Intl.message('Recorded', name: 'Recorded', desc: '', args: []);
  }

  /// `Lateness`
  String get Lateness {
    return Intl.message('Lateness', name: 'Lateness', desc: '', args: []);
  }

  /// `Early Leave`
  String get EarlyLeave {
    return Intl.message('Early Leave', name: 'EarlyLeave', desc: '', args: []);
  }

  /// `Approved OT`
  String get ApprovedOT {
    return Intl.message('Approved OT', name: 'ApprovedOT', desc: '', args: []);
  }

  /// `Today`
  String get Today {
    return Intl.message('Today', name: 'Today', desc: '', args: []);
  }

  /// `Yesterday`
  String get Yesterday {
    return Intl.message('Yesterday', name: 'Yesterday', desc: '', args: []);
  }

  /// `This Week`
  String get ThisWeek {
    return Intl.message('This Week', name: 'ThisWeek', desc: '', args: []);
  }

  /// `Last Week`
  String get LastWeek {
    return Intl.message('Last Week', name: 'LastWeek', desc: '', args: []);
  }

  /// `This Month`
  String get ThisMonth {
    return Intl.message('This Month', name: 'ThisMonth', desc: '', args: []);
  }

  /// `Last Month`
  String get LastMonth {
    return Intl.message('Last Month', name: 'LastMonth', desc: '', args: []);
  }

  /// `This Year`
  String get ThisYear {
    return Intl.message('This Year', name: 'ThisYear', desc: '', args: []);
  }

  /// `Last Year`
  String get LastYear {
    return Intl.message('Last Year', name: 'LastYear', desc: '', args: []);
  }

  /// `Today's Attendance`
  String get TodayAttendance {
    return Intl.message(
      'Today\'s Attendance',
      name: 'TodayAttendance',
      desc: '',
      args: [],
    );
  }

  /// `Profile`
  String get Profile {
    return Intl.message('Profile', name: 'Profile', desc: '', args: []);
  }

  /// `Settings`
  String get Settings {
    return Intl.message('Settings', name: 'Settings', desc: '', args: []);
  }

  /// `History`
  String get History {
    return Intl.message('History', name: 'History', desc: '', args: []);
  }

  /// `Alerts`
  String get Alerts {
    return Intl.message('Alerts', name: 'Alerts', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
