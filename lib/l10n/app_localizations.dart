import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Badge on the home attendance card when the user hasn't checked in today
  ///
  /// In en, this message translates to:
  /// **'Not Checked In'**
  String get notCheckedIn;

  /// No description provided for @currentLocalTime.
  ///
  /// In en, this message translates to:
  /// **'Current Local Time'**
  String get currentLocalTime;

  /// No description provided for @checkInNow.
  ///
  /// In en, this message translates to:
  /// **'Check In Now'**
  String get checkInNow;

  /// Shift hours under the check-in button
  ///
  /// In en, this message translates to:
  /// **'Official shift · {start}–{end}'**
  String officialShift(String start, String end);

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hoursCount(int count);

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @todayOverview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Overview'**
  String get todayOverview;

  /// No description provided for @recorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get recorded;

  /// No description provided for @lateness.
  ///
  /// In en, this message translates to:
  /// **'Lateness'**
  String get lateness;

  /// No description provided for @earlyLeave.
  ///
  /// In en, this message translates to:
  /// **'Early Leave'**
  String get earlyLeave;

  /// No description provided for @approvedOT.
  ///
  /// In en, this message translates to:
  /// **'Approved OT'**
  String get approvedOT;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @needToWorkLater.
  ///
  /// In en, this message translates to:
  /// **'Need to work later?'**
  String get needToWorkLater;

  /// No description provided for @requestOverTime.
  ///
  /// In en, this message translates to:
  /// **'Request Overtime For Manager Approval'**
  String get requestOverTime;

  /// No description provided for @needCash.
  ///
  /// In en, this message translates to:
  /// **'Need a cash advance?'**
  String get needCash;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send a request to your administrator'**
  String get sendRequest;

  /// No description provided for @attendanceDetails.
  ///
  /// In en, this message translates to:
  /// **'Attendance Details'**
  String get attendanceDetails;

  /// No description provided for @needsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs Review'**
  String get needsReview;

  /// No description provided for @automaticClosed.
  ///
  /// In en, this message translates to:
  /// **'Automatically closed'**
  String get automaticClosed;

  /// No description provided for @noEmployee.
  ///
  /// In en, this message translates to:
  /// **'No employee checkout recorded'**
  String get noEmployee;

  /// No description provided for @noCheckout.
  ///
  /// In en, this message translates to:
  /// **'No checkout selfie or GPS location exists for this event'**
  String get noCheckout;

  /// No description provided for @workSummary.
  ///
  /// In en, this message translates to:
  /// **'Work summary'**
  String get workSummary;

  /// No description provided for @attendanceEvents.
  ///
  /// In en, this message translates to:
  /// **'Attendance events'**
  String get attendanceEvents;

  /// No description provided for @withinGracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Within grace period'**
  String get withinGracePeriod;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkIn;

  /// No description provided for @selfieAndGps.
  ///
  /// In en, this message translates to:
  /// **'Selfie and GPS evidence captured'**
  String get selfieAndGps;

  /// No description provided for @systemGenerated.
  ///
  /// In en, this message translates to:
  /// **'System generated'**
  String get systemGenerated;

  /// No description provided for @autoClosed.
  ///
  /// In en, this message translates to:
  /// **'Auto-closed'**
  String get autoClosed;

  /// No description provided for @noLocationOrSelfie.
  ///
  /// In en, this message translates to:
  /// **'No location or selfie captured'**
  String get noLocationOrSelfie;

  /// No description provided for @flaggedForAdmin.
  ///
  /// In en, this message translates to:
  /// **'Flagged for administrative review'**
  String get flaggedForAdmin;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
