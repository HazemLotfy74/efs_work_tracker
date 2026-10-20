// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get notCheckedIn => 'لم يتم تسجيل الحضور';

  @override
  String get currentLocalTime => 'الوقت المحلي الحالي';

  @override
  String get checkInNow => 'سجّل الحضور الآن';

  @override
  String officialShift(String start, String end) {
    return 'مواعيد العمل الرسمية · $start–$end';
  }

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعة',
      many: '$count ساعة',
      few: '$count ساعات',
      two: 'ساعتان',
      one: 'ساعة واحدة',
      zero: 'لا ساعات',
    );
    return '$_temp0';
  }

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get home => 'الرئيسية';

  @override
  String get attendance => 'Attendance';

  @override
  String get viewDetails => 'المزيد';

  @override
  String get todayOverview => 'سجل اليوم';

  @override
  String get recorded => 'المسجل';

  @override
  String get lateness => 'التأخير';

  @override
  String get earlyLeave => 'الاذونات';

  @override
  String get approvedOT => 'ساعات اضافية';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get profile => 'ملفك الشخصي';

  @override
  String get settings => 'Settings';

  @override
  String get history => 'التواريخ';

  @override
  String get alerts => 'الاشعارات';

  @override
  String get needToWorkLater => 'هل تريد ساعات عمل اضافية؟';

  @override
  String get requestOverTime => 'اطلب ساعات اضافية للعمل';

  @override
  String get needCash => 'هل تحتاج طلب اعانة';

  @override
  String get sendRequest => 'ارسل طلب للمدير';
}
