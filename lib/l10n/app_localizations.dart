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

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// Badge on the check-in success screen
  ///
  /// In en, this message translates to:
  /// **'Checked In'**
  String get checkedIn;

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

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signWithAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your company account to continue.'**
  String get signWithAccount;

  /// No description provided for @workEmail.
  ///
  /// In en, this message translates to:
  /// **'Work email'**
  String get workEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @accountRecovery.
  ///
  /// In en, this message translates to:
  /// **'Account recovery'**
  String get accountRecovery;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPassword;

  /// No description provided for @enterRecEmailToSendLink.
  ///
  /// In en, this message translates to:
  /// **'Enter your work email and we’ll send secure recovery instructions.'**
  String get enterRecEmailToSendLink;

  /// No description provided for @sendRecLink.
  ///
  /// In en, this message translates to:
  /// **'Send recovery link'**
  String get sendRecLink;

  /// No description provided for @attendanceMadeClear.
  ///
  /// In en, this message translates to:
  /// **'Attendance made clear, wherever work happens.'**
  String get attendanceMadeClear;

  /// No description provided for @secureAccess.
  ///
  /// In en, this message translates to:
  /// **'Secure access to your WorkTrack account.'**
  String get secureAccess;

  /// No description provided for @contactYourAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact your administrator if you no longer have access to your work email.'**
  String get contactYourAdmin;

  /// No description provided for @checkInPage.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkInPage;

  /// No description provided for @prepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get prepare;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @selfie.
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get selfie;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @readyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready To Start?'**
  String get readyToStart;

  /// No description provided for @captureLocAndSelfie.
  ///
  /// In en, this message translates to:
  /// **'We’ll capture a current selfie and GPS location as attendance evidence.'**
  String get captureLocAndSelfie;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @currentTime.
  ///
  /// In en, this message translates to:
  /// **'Current Time'**
  String get currentTime;

  /// No description provided for @shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shift;

  /// No description provided for @yourSelfie.
  ///
  /// In en, this message translates to:
  /// **'Your selfie and location are used only to verify this attendance event.'**
  String get yourSelfie;

  /// No description provided for @continueTo.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueTo;

  /// No description provided for @verifyYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Location'**
  String get verifyYourLocation;

  /// No description provided for @keepYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Keep location services on while we securely capture your current position.'**
  String get keepYourLocation;

  /// No description provided for @locationVerified.
  ///
  /// In en, this message translates to:
  /// **'Location verified'**
  String get locationVerified;

  /// No description provided for @havingTrouble.
  ///
  /// In en, this message translates to:
  /// **'Having trouble with location?'**
  String get havingTrouble;

  /// No description provided for @useThisLoc.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get useThisLoc;

  /// No description provided for @takeQuickSelfie.
  ///
  /// In en, this message translates to:
  /// **'Take a quick selfie'**
  String get takeQuickSelfie;

  /// No description provided for @positionYourFace.
  ///
  /// In en, this message translates to:
  /// **'Position your face inside the guide and use a well-lit area.'**
  String get positionYourFace;

  /// No description provided for @reviewAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Review & confirm'**
  String get reviewAndConfirm;

  /// No description provided for @makeSure.
  ///
  /// In en, this message translates to:
  /// **'Make sure these details are correct before submitting.'**
  String get makeSure;

  /// No description provided for @selfieReady.
  ///
  /// In en, this message translates to:
  /// **'Selfie ready'**
  String get selfieReady;

  /// No description provided for @attendanceEvidence.
  ///
  /// In en, this message translates to:
  /// **'Attendance evidence'**
  String get attendanceEvidence;

  /// No description provided for @captureAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Capture & continue'**
  String get captureAndContinue;

  /// No description provided for @confirmCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Confirm check-in'**
  String get confirmCheckIn;

  /// No description provided for @youAreAllSet.
  ///
  /// In en, this message translates to:
  /// **'You’re all set!'**
  String get youAreAllSet;

  /// No description provided for @yourSessionIsNowActive.
  ///
  /// In en, this message translates to:
  /// **'Your attendance session is now active. Have a productive day.'**
  String get yourSessionIsNowActive;

  /// No description provided for @confirmedAt.
  ///
  /// In en, this message translates to:
  /// **'Confirmed At'**
  String get confirmedAt;

  /// No description provided for @selfieSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Selfie submitted'**
  String get selfieSubmitted;

  /// No description provided for @returnToHome.
  ///
  /// In en, this message translates to:
  /// **'Return to home'**
  String get returnToHome;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locating;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// Reported GPS accuracy and the time of the reading on the Location step
  ///
  /// In en, this message translates to:
  /// **'Accuracy · {meters} meters · Captured at {time}'**
  String locationAccuracy(int meters, String time);

  /// No description provided for @coordinatesPrivate.
  ///
  /// In en, this message translates to:
  /// **'Exact coordinates are kept private.'**
  String get coordinatesPrivate;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off. Turn them on to continue.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to verify your attendance.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked. Allow it in the app settings to continue.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationTimeout.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t get a GPS fix in time. Move to an open area and try again.'**
  String get locationTimeout;

  /// No description provided for @locationUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while getting your location.'**
  String get locationUnknownError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @clickHereToUpload.
  ///
  /// In en, this message translates to:
  /// **'Click here to upload your selfie'**
  String get clickHereToUpload;

  /// Step counter in the check-in app bar
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @checkInTime.
  ///
  /// In en, this message translates to:
  /// **'Check-in time'**
  String get checkInTime;

  /// Time the selfie was taken, on the Review step
  ///
  /// In en, this message translates to:
  /// **'Captured at {time}'**
  String capturedAt(String time);

  /// No description provided for @checkOutPage.
  ///
  /// In en, this message translates to:
  /// **'Check out'**
  String get checkOutPage;

  /// No description provided for @checkOutTime.
  ///
  /// In en, this message translates to:
  /// **'Check-out time'**
  String get checkOutTime;

  /// No description provided for @confirmCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Confirm check-out'**
  String get confirmCheckOut;

  /// No description provided for @checkedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked Out'**
  String get checkedOut;

  /// No description provided for @workdayRecorded.
  ///
  /// In en, this message translates to:
  /// **'Workday recorded'**
  String get workdayRecorded;

  /// No description provided for @checkoutRecorded.
  ///
  /// In en, this message translates to:
  /// **'Your checkout was recorded successfully.'**
  String get checkoutRecorded;

  /// No description provided for @checkoutRecordedEarly.
  ///
  /// In en, this message translates to:
  /// **'Your checkout was recorded successfully. The early departure has been flagged for review.'**
  String get checkoutRecordedEarly;

  /// No description provided for @finalDuration.
  ///
  /// In en, this message translates to:
  /// **'Final duration'**
  String get finalDuration;

  /// No description provided for @viewAttendanceDetails.
  ///
  /// In en, this message translates to:
  /// **'View attendance details'**
  String get viewAttendanceDetails;

  /// No description provided for @recordedDuration.
  ///
  /// In en, this message translates to:
  /// **'Recorded duration'**
  String get recordedDuration;

  /// No description provided for @earlyDeparture.
  ///
  /// In en, this message translates to:
  /// **'Early departure'**
  String get earlyDeparture;

  /// No description provided for @earlyDepartureMessage.
  ///
  /// In en, this message translates to:
  /// **'This checkout is {duration} before shift end and may require review.'**
  String earlyDepartureMessage(String duration);

  /// No description provided for @elapsedWorkingTime.
  ///
  /// In en, this message translates to:
  /// **'Elapsed working time'**
  String get elapsedWorkingTime;

  /// No description provided for @totalWorkingTime.
  ///
  /// In en, this message translates to:
  /// **'Total working time'**
  String get totalWorkingTime;

  /// No description provided for @shiftEnds.
  ///
  /// In en, this message translates to:
  /// **'Shift ends'**
  String get shiftEnds;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// A duration of an hour or more, e.g. 7h 19m
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(int hours, int minutes);

  /// A duration under an hour, e.g. 34m
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String durationMinutes(int minutes);

  /// No description provided for @saveAttendanceFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your attendance. Check your connection and try again.'**
  String get saveAttendanceFailed;

  /// No description provided for @attendanceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load today\'s attendance.'**
  String get attendanceLoadFailed;

  /// Location row value on the Review step
  ///
  /// In en, this message translates to:
  /// **'Verified · {meters}m'**
  String verifiedAccuracy(int meters);
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
