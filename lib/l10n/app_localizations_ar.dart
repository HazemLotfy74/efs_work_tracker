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
  String get approvedOT => 'العمل الإضافي';

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
    return 'ينقص هذا الانصراف $duration عن 8 ساعات عمل أساسية وقد يحتاج إلى مراجعة.';
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

  @override
  String get overTimeRequests => ' الساعات الإضافية';

  @override
  String get approvedThisMonth => 'تمت الموافقة عليها هذا الشهر';

  @override
  String get pendingDecision => 'بانتظار القرار';

  @override
  String get pendingApproval => 'بانتظار الموافقة';

  @override
  String get approved => 'تمت الموافقة';

  @override
  String get rejected => 'مرفوضة';

  @override
  String get recentRequests => 'الطلبات الأخيرة';

  @override
  String get request => 'طلب';

  @override
  String get all => 'الكل';

  @override
  String get createOverTimeRequest => 'طلب ساعات اضافية';

  @override
  String get requestOverTimePage => 'طلب عمل إضافي لموافقة المدير';

  @override
  String get approvalRequired => 'موافقة المدير مطلوبة';

  @override
  String get workingAfter4 =>
      'الشغل بعد الساعة 4 مساءً مش معناه إن الوقت الإضافي اتوافق عليه تلقائيًا.';

  @override
  String get requestedScheduled => 'مواعيد العمل المطلوبة';

  @override
  String get startTime => 'وقت البداية';

  @override
  String get endTome => 'وقت النهاية';

  @override
  String get requestedDuration => 'مدة العمل الإضافي المطلوبة';

  @override
  String get reasonForOverTime => 'سبب طلب العمل الإضافي';

  @override
  String get requestSummary => 'ملخص الطلب';

  @override
  String get approvalStatus => 'حالة الموافقة';

  @override
  String get requestSubmitted => 'تم إرسال الطلب';

  @override
  String get pendingRequests => 'طلبات المصروفات المعلقة';

  @override
  String get cashRequestReview => 'طلبات المصروفات بيراجعها مسؤول الشركة.';

  @override
  String get requestHistory => 'سجل الطلبات';

  @override
  String get newCashRequest => 'طلب مصروفات جديد';

  @override
  String get approvalRequiredForCash => 'موافقة مسؤول الشركة مطلوبة';

  @override
  String get submittingApproval =>
      'إرسال الطلب مش معناه إنه هيتوافق عليه تلقائيًا.';

  @override
  String get requestAmount => 'قيمة المصروفات المطلوبة';

  @override
  String get reasonForRequest => 'سبب طلب المصروفات';

  @override
  String get employee => 'الموظف';

  @override
  String get amount => 'المبلغ';

  @override
  String get statusAfterRequest => 'حالة الطلب بعد الإرسال';

  @override
  String get sendToAdmin => 'إرسال لمسؤول الشركة';

  @override
  String get cashRequests => 'طلبات المصروفات';

  @override
  String get overtimeBefore4pm => 'قبل 4:00 م';

  @override
  String get overtimeAfter4pm => 'بعد 4:00 م';

  @override
  String get overtimePeriod => 'الفترة';

  @override
  String get fewerHours => 'ساعات أقل';

  @override
  String get moreHours => 'ساعات أكثر';

  @override
  String get overtimeLoadFailed => 'تعذر تحميل طلبات الساعات الإضافية.';

  @override
  String get overtimeEmptyTitle => 'لا توجد طلبات ساعات إضافية';

  @override
  String get overtimeEmptyMessage =>
      'ستظهر هنا طلبات الساعات الإضافية التي ترسلها.';

  @override
  String get overtimeSubmittedMessage =>
      'تم إرسال طلبك إلى المسؤول. لا تُحتسب الساعات الإضافية إلا بعد موافقة المسؤول.';

  @override
  String get backToRequests => 'العودة إلى الطلبات';

  @override
  String get requestDetails => 'تفاصيل الطلب';

  @override
  String get requestNotFound => 'لم يتم العثور على هذا الطلب.';

  @override
  String get submittedAt => 'تاريخ الإرسال';

  @override
  String get reviewedAt => 'تاريخ المراجعة';

  @override
  String get reviewNote => 'ملاحظة المسؤول';

  @override
  String get cashLoadFailed => 'تعذر تحميل طلبات المصروفات.';

  @override
  String get cashEmptyTitle => 'لا توجد طلبات مصروفات';

  @override
  String get cashEmptyMessage => 'ستظهر هنا طلبات المصروفات التي ترسلها.';

  @override
  String get cashSubmittedMessage =>
      'تم إرسال الطلب. سيظل قيد الانتظار حتى يراجعه المسؤول.';

  @override
  String get cashAmountRequired => 'أدخل المبلغ.';

  @override
  String get cashAmountInvalid =>
      'أدخل مبلغًا أكبر من 0 بحد أقصى رقمين عشريين.';

  @override
  String moneyAmount(String amount, String currency) {
    return '$amount $currency';
  }

  @override
  String get requestReasonRequired => 'أدخل السبب.';

  @override
  String get requestReasonTooLong =>
      'يمكن أن يحتوي السبب على 2000 حرف كحد أقصى.';

  @override
  String get requestReasonInvalid => 'أدخل سببًا لا يزيد عن 2000 حرف.';

  @override
  String get requestAccountNotReady =>
      'لا يمكن لحسابك إرسال طلبات حاليًا. سجّل الدخول مرة أخرى أو تواصل مع المسؤول.';

  @override
  String get overtimeDuplicate =>
      'لديك بالفعل طلب ساعات إضافية قيد الانتظار أو تمت الموافقة عليه لهذا اليوم وهذه الفترة.';

  @override
  String get overtimeHoursInvalid => 'اختر ساعة واحدة على الأقل.';

  @override
  String get requestInvalidCurrency => 'هذه العملة غير مدعومة.';

  @override
  String get requestInvalidInput =>
      'بعض البيانات غير صحيحة. راجعها وحاول مرة أخرى.';

  @override
  String get requestBusy => 'يتم إرسال طلب بالفعل.';

  @override
  String get requestOutcomeUnknown =>
      'تعذر التأكد من إرسال طلبك. تحقق من الاتصال ثم اضغط إرسال مرة أخرى: سيتحقق التطبيق أولًا ولن يرسله مرتين.';

  @override
  String get requestNetworkError =>
      'تعذر الوصول إلى الخادم. لم يتم إرسال طلبك. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get requestServiceUnavailable => 'الطلبات غير متاحة حاليًا.';

  @override
  String get requestUnknownError => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get authInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authAccountUnavailable => 'هذا الحساب غير متاح. تواصل مع المسؤول.';

  @override
  String get authEmailNotConfirmed => 'لم يتم تأكيد بريدك الإلكتروني بعد.';

  @override
  String get authTooManyRequests =>
      'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String get authWeakPassword =>
      'كلمة المرور لا تستوفي قواعد الأمان. اختر كلمة مرور أقوى.';

  @override
  String get authSamePassword =>
      'اختر كلمة مرور مختلفة عن كلمة المرور الحالية.';

  @override
  String get authReauthenticationNeeded =>
      'لحمايتك، سجّل الدخول مرة أخرى قبل تغيير كلمة المرور.';

  @override
  String get authPasswordCompletionPending =>
      'ربما تم تغيير كلمة المرور. سجّل الدخول بكلمة المرور الجديدة ثم عيّن كلمة مرور أخرى لإكمال الإعداد.';

  @override
  String get authSessionExpired => 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get authNetworkError =>
      'تعذّر الوصول إلى الخادم. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get authUnknownError => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get accountSetup => 'إعداد الحساب';

  @override
  String get changePasswordTitle => 'تعيين كلمة مرور جديدة';

  @override
  String get changePasswordSubtitle =>
      'لحمايتك، اختر كلمة مرور جديدة قبل المتابعة.';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordRules => 'استخدم 12 حرفًا على الأقل.';

  @override
  String get savePassword => 'حفظ كلمة المرور';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get recoveryLinkSent =>
      'إذا كان هذا البريد مرتبطًا بحساب، فستصلك تعليمات الاستعادة قريبًا.';

  @override
  String get attendanceAccountNotReady =>
      'لا يمكن لحسابك تسجيل الحضور الآن. سجّل الدخول مرة أخرى أو تواصل مع المسؤول.';

  @override
  String get attendanceNoSchedule =>
      'لا يوجد جدول عمل مرتبط بحسابك. تواصل مع المسؤول.';

  @override
  String get attendanceNotWorkingDay => 'اليوم ليس يوم عمل في جدولك.';

  @override
  String get attendanceCheckInClosed =>
      'انتهت وردية اليوم، لذلك أُغلق تسجيل الحضور.';

  @override
  String get attendanceAlreadyCheckedIn => 'لقد سجّلت حضورك اليوم بالفعل.';

  @override
  String get attendanceNotCheckedIn =>
      'لا يوجد تسجيل حضور اليوم لتسجيل الانصراف منه.';

  @override
  String get attendanceAlreadyCheckedOut => 'تم تسجيل انصرافك بالفعل.';

  @override
  String get attendanceClosedAutomatically =>
      'تم إغلاق يومك تلقائيًا بالفعل، لذلك لا يمكن تسجيل الانصراف. يجب أن يراجع المسؤول هذا اليوم.';

  @override
  String get regularHoursEnd => 'اكتمال 8 ساعات';

  @override
  String get attendanceWorkDateChanged =>
      'تغيّر يوم العمل أثناء الحفظ. يرجى المحاولة مرة أخرى.';

  @override
  String get attendanceInvalidLocation =>
      'تعذّر التحقق من موقعك. ارجع إلى خطوة الموقع وحاول مرة أخرى.';

  @override
  String get attendanceSelfieMissing =>
      'لم يتم استلام صورة السيلفي. التقطها مرة أخرى وأعد المحاولة.';

  @override
  String get attendanceSelfieUploadFailed =>
      'تعذّر رفع صورة السيلفي. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get attendanceBusy => 'جارٍ حفظ حضورك بالفعل.';

  @override
  String get attendanceOutcomeUnknown =>
      'تعذّر التأكد من حفظ حضورك. راجع الصفحة الرئيسية قبل المحاولة مرة أخرى.';

  @override
  String get attendanceServiceUnavailable =>
      'يتم تحديث خدمة الحضور. يرجى المحاولة لاحقًا.';

  @override
  String get attendanceUnknownError =>
      'حدث خطأ في تسجيل حضورك. يرجى المحاولة مرة أخرى.';

  @override
  String get noShiftToday => 'لا توجد وردية اليوم';

  @override
  String get closedAutomatically => 'أُغلق تلقائيًا';

  @override
  String get closedAt => 'وقت الإغلاق';

  @override
  String autoClosedNote(String time) {
    return 'تم إغلاق يومك تلقائيًا الساعة $time دون تسجيل انصراف، لذلك ساعات عملك غير مؤكدة ويجب أن يراجعها المسؤول. إذا عملت وقتًا إضافيًا، أرسل طلب وقت إضافي.';
  }

  @override
  String closesBeforeRegularHours(String time) {
    return 'يُغلق الحضور تلقائيًا الساعة $time قبل اكتمال 8 ساعات العمل الأساسية. سجّل انصرافك قبل ذلك.';
  }

  @override
  String get notConfirmed => 'غير مؤكدة';

  @override
  String get regularHours => 'الساعات الأساسية';

  @override
  String get observedOvertime => 'العمل الإضافي';

  @override
  String get observedOvertimeNote =>
      'يُحسب تلقائيًا: كل دقيقة عمل بعد 8 ساعات.';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get attendanceNotFound => 'لم يتم العثور على سجل الحضور هذا.';

  @override
  String get historyEmptyTitle => 'لا يوجد حضور بعد';

  @override
  String get historyEmptyMessage => 'ستظهر أيام حضورك هنا.';

  @override
  String get historyLoadFailed => 'تعذّر تحميل سجل حضورك.';

  @override
  String lateMinutes(int minutes) {
    return 'متأخر $minutes دقيقة';
  }

  @override
  String get onTime => 'في الموعد';

  @override
  String get employeeCode => 'الرقم الوظيفي';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get role => 'الدور';

  @override
  String get roleAdmin => 'مسؤول';

  @override
  String get roleEmployee => 'موظف';

  @override
  String get workSchedule => 'جدول العمل';

  @override
  String get requestCorrection => 'طلب تصحيح';

  @override
  String get correctionTitle => 'تصحيح الحضور';

  @override
  String get correctionIntro =>
      'أُغلق هذا اليوم تلقائيًا، لذلك ساعاته غير مؤكدة. أدخل الأوقات التي عملت فيها فعلًا وسيراجعها أحد المسؤولين.';

  @override
  String get correctionCheckIn => 'وقت الحضور';

  @override
  String get correctionCheckOut => 'وقت الانصراف';

  @override
  String get correctionPickTime => 'اختر الوقت';

  @override
  String get correctionReason => 'السبب';

  @override
  String get correctionReasonHint => 'لماذا لم يُسجَّل الانصراف؟';

  @override
  String correctionTimezoneNote(String timezone) {
    return 'الأوقات بتوقيت الشركة ($timezone).';
  }

  @override
  String get correctionSubmit => 'إرسال الطلب';

  @override
  String get correctionSubmitted => 'تم إرسال طلب التصحيح.';

  @override
  String get correctionRequest => 'طلب التصحيح';

  @override
  String get correctionProposedTimes => 'الأوقات المقترحة';

  @override
  String get correctionReviewNote => 'ملاحظة المراجع';

  @override
  String get correctionLoadFailed => 'تعذر تحميل طلبات التصحيح.';

  @override
  String get correctionResubmit => 'يمكنك إرسال طلب جديد.';

  @override
  String get correctionPendingNote => 'سيراجع أحد المسؤولين هذا الطلب.';

  @override
  String get adminCorrections => 'طلبات التصحيح';

  @override
  String get adminCorrectionsEmptyTitle => 'لا توجد طلبات معلقة';

  @override
  String get adminCorrectionsEmptyMessage =>
      'ستظهر هنا طلبات التصحيح من الموظفين.';

  @override
  String get adminCorrectionsLoadFailed => 'تعذر تحميل طلبات التصحيح.';

  @override
  String get correctionRecordedCheckIn => 'الحضور المسجل';

  @override
  String get correctionApprove => 'قبول';

  @override
  String get correctionReject => 'رفض';

  @override
  String get correctionApproveTitle => 'قبول هذا التصحيح؟';

  @override
  String get correctionRejectTitle => 'رفض هذا التصحيح؟';

  @override
  String get correctionApproveMessage =>
      'تصبح الأوقات المقترحة هي الساعات المؤكدة لهذا اليوم.';

  @override
  String get correctionRejectMessage =>
      'يبقى اليوم غير مؤكد، ويمكن للموظف إرسال طلب جديد.';

  @override
  String get correctionNoteOptional => 'ملاحظة (اختياري)';

  @override
  String get correctionCancel => 'إلغاء';

  @override
  String get correctionApprovedDone => 'تم قبول التصحيح.';

  @override
  String get correctionRejectedDone => 'تم رفض التصحيح.';

  @override
  String get correctionNotAllowed => 'لا يمكن لحسابك القيام بذلك الآن.';

  @override
  String get correctionOwnRequest => 'لا يمكنك مراجعة طلبك الخاص.';

  @override
  String get correctionNotFound => 'يوم الحضور أو الطلب لم يعد موجودًا.';

  @override
  String get correctionNotClosed => 'لا يمكن تصحيح إلا يوم مغلق.';

  @override
  String get correctionInvalidTimes =>
      'يجب أن يكون الحضور في يوم العمل وقبل نهاية الوردية، وأن يكون الانصراف بعد الحضور وقبل منتصف الليل.';

  @override
  String get correctionMissingCheckOut => 'اختر وقت الانصراف.';

  @override
  String get correctionInvalidReason => 'أدخل سببًا لا يزيد على 2000 حرف.';

  @override
  String get correctionNoteTooLong => 'لا يمكن أن تزيد الملاحظة على 2000 حرف.';

  @override
  String get correctionNoChange => 'هذه هي الأوقات المعتمدة بالفعل.';

  @override
  String get correctionAlreadyPending =>
      'يوجد طلب لهذا اليوم بانتظار المراجعة.';

  @override
  String get correctionAlreadyReviewed => 'تمت مراجعة هذا الطلب بالفعل.';

  @override
  String get correctionAttendanceChanged =>
      'تغيّر هذا اليوم بعد إرسال الطلب. ارفضه ليتمكن الموظف من إرسال طلب جديد.';

  @override
  String get correctionBusy => 'يتم إرسال طلب بالفعل.';

  @override
  String get correctionNetwork =>
      'تعذر الوصول إلى الخادم. تحقق من حالة الطلب قبل المحاولة مرة أخرى.';

  @override
  String get correctionServiceUnavailable => 'التصحيحات غير متاحة حاليًا.';

  @override
  String get correctionUnknownError => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get adminDashboard => 'لوحة الإدارة';

  @override
  String get adminToday => 'اليوم';

  @override
  String get adminCheckedInNow => 'حاضرون الآن';

  @override
  String get adminPastShiftEnd => 'ما زال حاضرًا بعد نهاية الوردية';

  @override
  String get adminSearchHint => 'ابحث بالاسم أو اسم المستخدم أو الرمز';

  @override
  String get adminStaleData => 'تعذر التحديث. تُعرض بيانات سابقة.';

  @override
  String get adminLoadFailed => 'تعذر تحميل لوحة الإدارة.';

  @override
  String get adminNoEmployees => 'لا يوجد موظفون';

  @override
  String get adminInactive => 'غير نشط';

  @override
  String get adminFirstSignInPending => 'لم يسجّل الدخول بعد';

  @override
  String adminSince(String time) {
    return 'منذ $time';
  }

  @override
  String get adminHistoryEmpty => 'لا توجد أيام حضور بعد.';

  @override
  String get adminAddEmployee => 'إضافة موظف';

  @override
  String get adminRequests => 'طلبات النقدية';

  @override
  String get adminFullName => 'الاسم الكامل';

  @override
  String get adminInitialPassword => 'كلمة المرور الأولى';

  @override
  String get adminInitialPasswordHint =>
      '12 حرفًا على الأقل. يغيّرها الموظف عند أول تسجيل دخول.';

  @override
  String get adminCreateAccount => 'إنشاء الحساب';

  @override
  String adminAccountCreated(String name) {
    return 'تم إنشاء حساب $name. يسجّل الدخول بهذا البريد وكلمة المرور الأولى ثم يختار كلمة مرور جديدة.';
  }

  @override
  String get adminAddAnother => 'إضافة موظف آخر';

  @override
  String get adminSchedulesLoadFailed => 'تعذر تحميل جداول العمل.';

  @override
  String get adminInvalidFullName => 'أدخل من 1 إلى 200 حرف.';

  @override
  String get adminInvalidUsername =>
      'من 3 إلى 64 حرفًا إنجليزيًا صغيرًا أو رقمًا أو نقطة أو شرطة، ويبدأ بحرف أو رقم.';

  @override
  String get adminInvalidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا.';

  @override
  String get adminInvalidEmployeeCode => 'من 2 إلى 50 حرفًا أو رقمًا أو شرطة.';

  @override
  String get adminInvalidSchedule => 'اختر جدول عمل.';

  @override
  String get adminInvalidPassword =>
      'استخدم 12 حرفًا على الأقل (72 بايت كحد أقصى).';

  @override
  String get adminNotAllowed => 'لا يقوم بهذا إلا مسؤول نشط.';

  @override
  String get adminAccountConflict =>
      'اسم المستخدم أو رمز الموظف أو البريد مستخدم بالفعل.';

  @override
  String get adminInvalidInput =>
      'رفض الخادم هذه البيانات. راجعها وحاول مرة أخرى.';

  @override
  String get adminOutcomeUnknown =>
      'تعذر تأكيد النتيجة. حاول مرة أخرى؛ لا يُطبَّق الطلب نفسه مرتين.';

  @override
  String get adminTooManyRequests =>
      'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String get adminOwnRequest => 'لا يمكنك مراجعة طلبك الخاص.';

  @override
  String get adminAlreadyReviewed => 'تمت مراجعة هذا الطلب بالفعل.';

  @override
  String get adminNotFound => 'لم يعد هذا العنصر موجودًا.';

  @override
  String get adminBusy => 'يتم إرسال هذا بالفعل.';

  @override
  String get adminNetwork =>
      'تعذر الوصول إلى الخادم. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get adminWebOriginBlocked =>
      'رفضت خدمة الحسابات عنوان الويب هذا، ولم يُنشأ أي حساب. استخدم تطبيق الهاتف، أو اسمح بهذا العنوان في إعدادات الخدمة.';

  @override
  String get adminServiceUnavailable => 'هذا غير متاح حاليًا.';

  @override
  String get adminUnknownError => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get adminCashRequest => 'طلب نقدية';

  @override
  String get adminSubmitted => 'تاريخ الإرسال';

  @override
  String adminOvertimeHours(int hours) {
    return '$hours س';
  }

  @override
  String get adminRequestsEmptyMessage =>
      'ستظهر هنا طلبات النقدية من الموظفين.';

  @override
  String get adminApproveRequestTitle => 'قبول هذا الطلب؟';

  @override
  String get adminRejectRequestTitle => 'رفض هذا الطلب؟';

  @override
  String get adminRequestApproved => 'تم قبول الطلب.';

  @override
  String get adminRequestRejected => 'تم رفض الطلب.';

  @override
  String get language => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';
}
