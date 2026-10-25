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
  String get goodAfternoon => 'نهارك سعيد';

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String get checkedIn => 'تم تسجيل الحضور';

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

  @override
  String get attendanceDetails => 'تفاصيل الحضور';

  @override
  String get needsReview => 'يحتاج إلى مراجعة';

  @override
  String get automaticClosed => 'تسجيل انصراف تلقائي';

  @override
  String get noEmployee => 'لم يتم تسجيل انصراف الموظف';

  @override
  String get noCheckout => 'لم يتم تحديد الموقع أو التقاط صورة لهذه العملية';

  @override
  String get workSummary => 'ملخص العمل';

  @override
  String get attendanceEvents => 'أحداث الحضور والانصراف';

  @override
  String get withinGracePeriod => 'ضمن فترة السماح';

  @override
  String get checkIn => 'تسجيل الحضور';

  @override
  String get selfieAndGps => 'تم التقاط صورة شخصية وتسجيل الموقع الجغرافي';

  @override
  String get systemGenerated => 'تم إنشاؤه تلقائيًا بواسطة النظام';

  @override
  String get autoClosed => 'تم تسجيل الانصراف تلقائيًا';

  @override
  String get noLocationOrSelfie =>
      'لم يتم تسجيل الموقع الجغرافي أو التقاط صورة شخصية';

  @override
  String get flaggedForAdmin => 'تمت إحالته للمراجعة الإدارية';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get signWithAccount =>
      'سجّل الدخول باستخدام حساب العمل الخاص بك للمتابعة.';

  @override
  String get workEmail => 'البريد الإلكتروني للعمل';

  @override
  String get password => 'كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get backToSignIn => 'العودة إلى تسجيل الدخول';

  @override
  String get accountRecovery => 'استعادة الحساب';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get enterRecEmailToSendLink =>
      'أدخل بريدك الإلكتروني الخاص بالعمل، وسنرسل إليك تعليمات آمنة لاستعادة حسابك.';

  @override
  String get sendRecLink => 'إرسال رابط الاستعادة';

  @override
  String get attendanceMadeClear =>
      'إدارة الحضور والانصراف بوضوح، أينما كان مكان العمل.';

  @override
  String get secureAccess => 'وصول آمن إلى حسابك على WorkTrack.';

  @override
  String get contactYourAdmin =>
      'إذا لم يعد بإمكانك الوصول إلى بريدك الإلكتروني الخاص بالعمل، يُرجى التواصل مع مسؤول النظام.';

  @override
  String get checkInPage => 'تسجيل الحضور';

  @override
  String get prepare => 'الاستعداد';

  @override
  String get location => 'الموقع';

  @override
  String get selfie => 'صورة السيلفي';

  @override
  String get review => 'المراجعة';

  @override
  String get readyToStart => 'هل أنت مستعد للبدء؟';

  @override
  String get captureLocAndSelfie =>
      'سيتم التقاط صورة سيلفي حديثة وتحديد موقعك الحالي عبر GPS كدليل على تسجيل الحضور.';

  @override
  String get date => 'التاريخ';

  @override
  String get currentTime => 'الوقت الحالي';

  @override
  String get shift => 'الوردية';

  @override
  String get yourSelfie =>
      'تُستخدم صورة السيلفي وموقعك فقط للتحقق من عملية تسجيل الحضور.';

  @override
  String get continueTo => 'متابعة';

  @override
  String get verifyYourLocation => 'التحقق من موقعك';

  @override
  String get keepYourLocation =>
      'تأكد من تفعيل خدمات الموقع أثناء تحديد موقعك الحالي بشكل آمن.';

  @override
  String get locationVerified => 'تم التحقق من الموقع';

  @override
  String get havingTrouble => 'هل تواجه مشكلة في تحديد الموقع؟';

  @override
  String get useThisLoc => 'استخدام هذا الموقع';

  @override
  String get takeQuickSelfie => 'التقط صورة سيلفي سريعة';

  @override
  String get positionYourFace =>
      'ضع وجهك داخل الإطار المحدد، واحرص على وجود إضاءة جيدة.';

  @override
  String get reviewAndConfirm => 'المراجعة والتأكيد';

  @override
  String get makeSure => 'تأكد من صحة هذه البيانات قبل الإرسال.';

  @override
  String get selfieReady => 'صورة السيلفي جاهزة';

  @override
  String get attendanceEvidence => 'إثبات الحضور';

  @override
  String get captureAndContinue => 'التقاط الصورة والمتابعة';

  @override
  String get confirmCheckIn => 'تأكيد تسجيل الحضور';

  @override
  String get youAreAllSet => 'تم بنجاح!';

  @override
  String get yourSessionIsNowActive =>
      'تم تسجيل حضورك بنجاح. نتمنى لك يوم عمل مثمرًا.';

  @override
  String get confirmedAt => 'وقت التأكيد';

  @override
  String get selfieSubmitted => 'تم إرسال صورة السيلفي';

  @override
  String get returnToHome => 'العودة إلى الصفحة الرئيسية';

  @override
  String get locating => 'جارٍ تحديد موقعك…';

  @override
  String get currentLocation => 'موقعك الحالي';

  @override
  String locationAccuracy(int meters, String time) {
    return 'الدقة · $meters متر · تم الالتقاط $time';
  }

  @override
  String get coordinatesPrivate => 'تُحفظ الإحداثيات الدقيقة بشكل خاص.';

  @override
  String get locationUnavailable => 'تعذّر تحديد الموقع';

  @override
  String get locationServiceDisabled =>
      'خدمات الموقع متوقفة. قم بتشغيلها للمتابعة.';

  @override
  String get locationPermissionDenied =>
      'يلزم السماح بالوصول إلى الموقع للتحقق من حضورك.';

  @override
  String get locationPermissionDeniedForever =>
      'تم حظر الوصول إلى الموقع. اسمح به من إعدادات التطبيق للمتابعة.';

  @override
  String get locationTimeout =>
      'تعذّر تحديد موقعك عبر GPS في الوقت المحدد. انتقل إلى مكان مفتوح وحاول مرة أخرى.';

  @override
  String get locationUnknownError => 'حدث خطأ أثناء تحديد موقعك.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get clickHereToUpload => 'اضغط هنا لالتقاط الصوره';

  @override
  String stepOf(int current, int total) {
    return '$current من $total';
  }

  @override
  String get checkInTime => 'وقت تسجيل الحضور';

  @override
  String capturedAt(String time) {
    return 'تم الالتقاط $time';
  }

  @override
  String get checkOutPage => 'تسجيل الانصراف';

  @override
  String get checkOutTime => 'وقت الانصراف';

  @override
  String get confirmCheckOut => 'تأكيد تسجيل الانصراف';

  @override
  String get checkedOut => 'تم تسجيل الانصراف';

  @override
  String get workdayRecorded => 'تم تسجيل يوم العمل';

  @override
  String get checkoutRecorded => 'تم تسجيل انصرافك بنجاح.';

  @override
  String get checkoutRecordedEarly =>
      'تم تسجيل انصرافك بنجاح. تم تمييز الانصراف المبكر للمراجعة.';

  @override
  String get finalDuration => 'المدة النهائية';

  @override
  String get viewAttendanceDetails => 'عرض تفاصيل الحضور';

  @override
  String get recordedDuration => 'المدة المسجلة';

  @override
  String get earlyDeparture => 'انصراف مبكر';

  @override
  String earlyDepartureMessage(String duration) {
    return 'هذا الانصراف قبل نهاية الوردية بـ $duration وقد يحتاج إلى مراجعة.';
  }

  @override
  String get elapsedWorkingTime => 'وقت العمل المنقضي';

  @override
  String get totalWorkingTime => 'إجمالي وقت العمل';

  @override
  String get shiftEnds => 'نهاية الوردية';

  @override
  String get live => 'مباشر';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes د';
  }

  @override
  String get saveAttendanceFailed =>
      'تعذّر حفظ الحضور. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get attendanceLoadFailed => 'تعذّر تحميل حضور اليوم.';

  @override
  String verifiedAccuracy(int meters) {
    return 'تم التحقق · $meters م';
  }
}
