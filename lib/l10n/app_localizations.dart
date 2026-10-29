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
  /// **'Overtime'**
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
  /// **'This checkout is {duration} short of 8 regular hours and may require review.'**
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

  /// No description provided for @overTimeRequests.
  ///
  /// In en, this message translates to:
  /// **'Overtime requests'**
  String get overTimeRequests;

  /// No description provided for @approvedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Approved this month'**
  String get approvedThisMonth;

  /// No description provided for @pendingDecision.
  ///
  /// In en, this message translates to:
  /// **'Awaiting decision'**
  String get pendingDecision;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get pendingApproval;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @recentRequests.
  ///
  /// In en, this message translates to:
  /// **'Recent requests'**
  String get recentRequests;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @createOverTimeRequest.
  ///
  /// In en, this message translates to:
  /// **'Create Overtime Request'**
  String get createOverTimeRequest;

  /// No description provided for @requestOverTimePage.
  ///
  /// In en, this message translates to:
  /// **'Request Overtime For Manager Approval'**
  String get requestOverTimePage;

  /// No description provided for @approvalRequired.
  ///
  /// In en, this message translates to:
  /// **'Approval required'**
  String get approvalRequired;

  /// No description provided for @workingAfter4.
  ///
  /// In en, this message translates to:
  /// **'Working after 4:00 PM does not automatically mean overtime is approved.'**
  String get workingAfter4;

  /// No description provided for @requestedScheduled.
  ///
  /// In en, this message translates to:
  /// **'Requested schedule'**
  String get requestedScheduled;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @endTome.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTome;

  /// No description provided for @requestedDuration.
  ///
  /// In en, this message translates to:
  /// **'Requested duration'**
  String get requestedDuration;

  /// No description provided for @reasonForOverTime.
  ///
  /// In en, this message translates to:
  /// **'Reason for overtime'**
  String get reasonForOverTime;

  /// No description provided for @requestSummary.
  ///
  /// In en, this message translates to:
  /// **'Request summary'**
  String get requestSummary;

  /// No description provided for @approvalStatus.
  ///
  /// In en, this message translates to:
  /// **'Approval status'**
  String get approvalStatus;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get requestSubmitted;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequests;

  /// No description provided for @cashRequestReview.
  ///
  /// In en, this message translates to:
  /// **'Cash requests are reviewed by your company administrator.'**
  String get cashRequestReview;

  /// No description provided for @requestHistory.
  ///
  /// In en, this message translates to:
  /// **'Request history'**
  String get requestHistory;

  /// No description provided for @newCashRequest.
  ///
  /// In en, this message translates to:
  /// **'New cash request'**
  String get newCashRequest;

  /// No description provided for @approvalRequiredForCash.
  ///
  /// In en, this message translates to:
  /// **'Administrator approval required'**
  String get approvalRequiredForCash;

  /// No description provided for @submittingApproval.
  ///
  /// In en, this message translates to:
  /// **'Submitting this form does not guarantee that the request will be approved.'**
  String get submittingApproval;

  /// No description provided for @requestAmount.
  ///
  /// In en, this message translates to:
  /// **'Requested amount'**
  String get requestAmount;

  /// No description provided for @reasonForRequest.
  ///
  /// In en, this message translates to:
  /// **'Reason for request'**
  String get reasonForRequest;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @statusAfterRequest.
  ///
  /// In en, this message translates to:
  /// **'Status after sending'**
  String get statusAfterRequest;

  /// No description provided for @sendToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Send to administrator'**
  String get sendToAdmin;

  /// No description provided for @cashRequests.
  ///
  /// In en, this message translates to:
  /// **'Cash requests'**
  String get cashRequests;

  /// No description provided for @overtimeBefore4pm.
  ///
  /// In en, this message translates to:
  /// **'Before 4:00 PM'**
  String get overtimeBefore4pm;

  /// No description provided for @overtimeAfter4pm.
  ///
  /// In en, this message translates to:
  /// **'After 4:00 PM'**
  String get overtimeAfter4pm;

  /// No description provided for @overtimePeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get overtimePeriod;

  /// No description provided for @fewerHours.
  ///
  /// In en, this message translates to:
  /// **'Fewer hours'**
  String get fewerHours;

  /// No description provided for @moreHours.
  ///
  /// In en, this message translates to:
  /// **'More hours'**
  String get moreHours;

  /// No description provided for @overtimeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your overtime requests.'**
  String get overtimeLoadFailed;

  /// No description provided for @overtimeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No overtime requests'**
  String get overtimeEmptyTitle;

  /// No description provided for @overtimeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Overtime requests you send will appear here.'**
  String get overtimeEmptyMessage;

  /// No description provided for @overtimeSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your request was sent to your administrator. Overtime counts only after an administrator approves it.'**
  String get overtimeSubmittedMessage;

  /// No description provided for @backToRequests.
  ///
  /// In en, this message translates to:
  /// **'Back to requests'**
  String get backToRequests;

  /// No description provided for @requestDetails.
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get requestDetails;

  /// No description provided for @requestNotFound.
  ///
  /// In en, this message translates to:
  /// **'This request was not found.'**
  String get requestNotFound;

  /// No description provided for @submittedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedAt;

  /// No description provided for @reviewedAt.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reviewedAt;

  /// No description provided for @reviewNote.
  ///
  /// In en, this message translates to:
  /// **'Administrator note'**
  String get reviewNote;

  /// No description provided for @cashLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your cash requests.'**
  String get cashLoadFailed;

  /// No description provided for @cashEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No cash requests'**
  String get cashEmptyTitle;

  /// No description provided for @cashEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Cash requests you send will appear here.'**
  String get cashEmptyMessage;

  /// No description provided for @cashSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Request sent. It is pending until your administrator reviews it.'**
  String get cashSubmittedMessage;

  /// No description provided for @cashAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount.'**
  String get cashAmountRequired;

  /// No description provided for @cashAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0 with at most 2 decimal places.'**
  String get cashAmountInvalid;

  /// No description provided for @moneyAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} {currency}'**
  String moneyAmount(String amount, String currency);

  /// No description provided for @requestReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason.'**
  String get requestReasonRequired;

  /// No description provided for @requestReasonTooLong.
  ///
  /// In en, this message translates to:
  /// **'The reason can have at most 2000 characters.'**
  String get requestReasonTooLong;

  /// No description provided for @requestReasonInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason of up to 2000 characters.'**
  String get requestReasonInvalid;

  /// No description provided for @requestAccountNotReady.
  ///
  /// In en, this message translates to:
  /// **'Your account can’t send requests right now. Sign in again or contact your administrator.'**
  String get requestAccountNotReady;

  /// No description provided for @overtimeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending or approved overtime request for this day and period.'**
  String get overtimeDuplicate;

  /// No description provided for @overtimeHoursInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose at least 1 hour.'**
  String get overtimeHoursInvalid;

  /// No description provided for @requestInvalidCurrency.
  ///
  /// In en, this message translates to:
  /// **'This currency isn’t supported.'**
  String get requestInvalidCurrency;

  /// No description provided for @requestInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Some details aren’t valid. Check them and try again.'**
  String get requestInvalidInput;

  /// No description provided for @requestBusy.
  ///
  /// In en, this message translates to:
  /// **'A request is already being sent.'**
  String get requestBusy;

  /// No description provided for @requestOutcomeUnknown.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t confirm whether your request was sent. Check your connection, then tap send again: the app checks first and won’t send it twice.'**
  String get requestOutcomeUnknown;

  /// No description provided for @requestNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Can’t reach the server. Your request was not sent. Check your connection and try again.'**
  String get requestNetworkError;

  /// No description provided for @requestServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Requests aren’t available right now.'**
  String get requestServiceUnavailable;

  /// No description provided for @requestUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get requestUnknownError;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authInvalidCredentials;

  /// No description provided for @authAccountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This account is not available. Contact your administrator.'**
  String get authAccountUnavailable;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your email address has not been confirmed yet.'**
  String get authEmailNotConfirmed;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get authTooManyRequests;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'This password doesn’t meet the security rules. Choose a stronger one.'**
  String get authWeakPassword;

  /// No description provided for @authSamePassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a password different from your current one.'**
  String get authSamePassword;

  /// No description provided for @authReauthenticationNeeded.
  ///
  /// In en, this message translates to:
  /// **'For your security, sign in again before changing your password.'**
  String get authReauthenticationNeeded;

  /// No description provided for @authPasswordCompletionPending.
  ///
  /// In en, this message translates to:
  /// **'Your password may have changed. Sign in with the new password and set another one to finish.'**
  String get authPasswordCompletionPending;

  /// No description provided for @authSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get authSessionExpired;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Can’t reach the server. Check your connection and try again.'**
  String get authNetworkError;

  /// No description provided for @authUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authUnknownError;

  /// No description provided for @accountSetup.
  ///
  /// In en, this message translates to:
  /// **'Account setup'**
  String get accountSetup;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For your security, choose a new password before you continue.'**
  String get changePasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @passwordRules.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters.'**
  String get passwordRules;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePassword;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @recoveryLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If this email belongs to an account, recovery instructions are on their way.'**
  String get recoveryLinkSent;

  /// No description provided for @attendanceAccountNotReady.
  ///
  /// In en, this message translates to:
  /// **'Your account can’t record attendance right now. Sign in again or contact your administrator.'**
  String get attendanceAccountNotReady;

  /// No description provided for @attendanceNoSchedule.
  ///
  /// In en, this message translates to:
  /// **'No work schedule is assigned to your account. Contact your administrator.'**
  String get attendanceNoSchedule;

  /// No description provided for @attendanceNotWorkingDay.
  ///
  /// In en, this message translates to:
  /// **'Today is not a working day in your schedule.'**
  String get attendanceNotWorkingDay;

  /// No description provided for @attendanceCheckInClosed.
  ///
  /// In en, this message translates to:
  /// **'Today’s shift has ended, so check-in is closed.'**
  String get attendanceCheckInClosed;

  /// No description provided for @attendanceAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'You have already checked in today.'**
  String get attendanceAlreadyCheckedIn;

  /// No description provided for @attendanceNotCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'There is no check-in to check out from today.'**
  String get attendanceNotCheckedIn;

  /// No description provided for @attendanceAlreadyCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Your check-out was already recorded.'**
  String get attendanceAlreadyCheckedOut;

  /// No description provided for @attendanceClosedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Your day was already closed automatically, so a check-out can’t be recorded. An administrator has to review this day.'**
  String get attendanceClosedAutomatically;

  /// No description provided for @regularHoursEnd.
  ///
  /// In en, this message translates to:
  /// **'8 hours at'**
  String get regularHoursEnd;

  /// No description provided for @attendanceWorkDateChanged.
  ///
  /// In en, this message translates to:
  /// **'The work day changed while saving. Please try again.'**
  String get attendanceWorkDateChanged;

  /// No description provided for @attendanceInvalidLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location couldn’t be verified. Go back to the Location step and try again.'**
  String get attendanceInvalidLocation;

  /// No description provided for @attendanceSelfieMissing.
  ///
  /// In en, this message translates to:
  /// **'Your selfie wasn’t received. Take it again and retry.'**
  String get attendanceSelfieMissing;

  /// No description provided for @attendanceSelfieUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your selfie couldn’t be uploaded. Check your connection and try again.'**
  String get attendanceSelfieUploadFailed;

  /// No description provided for @attendanceBusy.
  ///
  /// In en, this message translates to:
  /// **'Your attendance is already being saved.'**
  String get attendanceBusy;

  /// No description provided for @attendanceOutcomeUnknown.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t confirm whether your attendance was saved. Check the home screen before trying again.'**
  String get attendanceOutcomeUnknown;

  /// No description provided for @attendanceServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Attendance is being updated. Please try again later.'**
  String get attendanceServiceUnavailable;

  /// No description provided for @attendanceUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with your attendance. Please try again.'**
  String get attendanceUnknownError;

  /// No description provided for @noShiftToday.
  ///
  /// In en, this message translates to:
  /// **'No shift today'**
  String get noShiftToday;

  /// No description provided for @closedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Closed automatically'**
  String get closedAutomatically;

  /// No description provided for @closedAt.
  ///
  /// In en, this message translates to:
  /// **'Closed at'**
  String get closedAt;

  /// No description provided for @autoClosedNote.
  ///
  /// In en, this message translates to:
  /// **'Your day was closed automatically at {time} without a check-out, so your hours are not confirmed and an administrator has to review them. If you worked later, send an overtime request.'**
  String autoClosedNote(String time);

  /// No description provided for @closesBeforeRegularHours.
  ///
  /// In en, this message translates to:
  /// **'Attendance closes automatically at {time}, before your 8 regular hours are complete. Check out before then.'**
  String closesBeforeRegularHours(String time);

  /// No description provided for @notConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get notConfirmed;

  /// No description provided for @regularHours.
  ///
  /// In en, this message translates to:
  /// **'Regular hours'**
  String get regularHours;

  /// No description provided for @observedOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get observedOvertime;

  /// No description provided for @observedOvertimeNote.
  ///
  /// In en, this message translates to:
  /// **'Counted automatically: every minute worked beyond 8 hours.'**
  String get observedOvertimeNote;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @attendanceNotFound.
  ///
  /// In en, this message translates to:
  /// **'This attendance record was not found.'**
  String get attendanceNotFound;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No attendance yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your attendance days will appear here.'**
  String get historyEmptyMessage;

  /// No description provided for @historyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load your attendance history.'**
  String get historyLoadFailed;

  /// No description provided for @lateMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min late'**
  String lateMinutes(int minutes);

  /// No description provided for @onTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get onTime;

  /// No description provided for @employeeCode.
  ///
  /// In en, this message translates to:
  /// **'Employee code'**
  String get employeeCode;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @roleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleEmployee;

  /// No description provided for @workSchedule.
  ///
  /// In en, this message translates to:
  /// **'Work schedule'**
  String get workSchedule;

  /// No description provided for @requestCorrection.
  ///
  /// In en, this message translates to:
  /// **'Request correction'**
  String get requestCorrection;

  /// No description provided for @correctionTitle.
  ///
  /// In en, this message translates to:
  /// **'Correct attendance'**
  String get correctionTitle;

  /// No description provided for @correctionIntro.
  ///
  /// In en, this message translates to:
  /// **'This day was closed automatically, so its hours aren’t confirmed. Enter the times you actually worked; an administrator will review them.'**
  String get correctionIntro;

  /// No description provided for @correctionCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in time'**
  String get correctionCheckIn;

  /// No description provided for @correctionCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out time'**
  String get correctionCheckOut;

  /// No description provided for @correctionPickTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get correctionPickTime;

  /// No description provided for @correctionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get correctionReason;

  /// No description provided for @correctionReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why is the check-out missing?'**
  String get correctionReasonHint;

  /// No description provided for @correctionTimezoneNote.
  ///
  /// In en, this message translates to:
  /// **'Times are in company time ({timezone}).'**
  String correctionTimezoneNote(String timezone);

  /// No description provided for @correctionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get correctionSubmit;

  /// No description provided for @correctionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Correction request sent.'**
  String get correctionSubmitted;

  /// No description provided for @correctionRequest.
  ///
  /// In en, this message translates to:
  /// **'Correction request'**
  String get correctionRequest;

  /// No description provided for @correctionProposedTimes.
  ///
  /// In en, this message translates to:
  /// **'Proposed times'**
  String get correctionProposedTimes;

  /// No description provided for @correctionReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Reviewer note'**
  String get correctionReviewNote;

  /// No description provided for @correctionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the correction requests.'**
  String get correctionLoadFailed;

  /// No description provided for @correctionResubmit.
  ///
  /// In en, this message translates to:
  /// **'You can send a new request.'**
  String get correctionResubmit;

  /// No description provided for @correctionPendingNote.
  ///
  /// In en, this message translates to:
  /// **'An administrator will review this request.'**
  String get correctionPendingNote;

  /// No description provided for @adminCorrections.
  ///
  /// In en, this message translates to:
  /// **'Correction requests'**
  String get adminCorrections;

  /// No description provided for @adminCorrectionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get adminCorrectionsEmptyTitle;

  /// No description provided for @adminCorrectionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Correction requests from employees will appear here.'**
  String get adminCorrectionsEmptyMessage;

  /// No description provided for @adminCorrectionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the correction requests.'**
  String get adminCorrectionsLoadFailed;

  /// No description provided for @correctionRecordedCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Recorded check-in'**
  String get correctionRecordedCheckIn;

  /// No description provided for @correctionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get correctionApprove;

  /// No description provided for @correctionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get correctionReject;

  /// No description provided for @correctionApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve this correction?'**
  String get correctionApproveTitle;

  /// No description provided for @correctionRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this correction?'**
  String get correctionRejectTitle;

  /// No description provided for @correctionApproveMessage.
  ///
  /// In en, this message translates to:
  /// **'The proposed times become the confirmed hours of this day.'**
  String get correctionApproveMessage;

  /// No description provided for @correctionRejectMessage.
  ///
  /// In en, this message translates to:
  /// **'The day stays unconfirmed. The employee can send a new request.'**
  String get correctionRejectMessage;

  /// No description provided for @correctionNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get correctionNoteOptional;

  /// No description provided for @correctionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get correctionCancel;

  /// No description provided for @correctionApprovedDone.
  ///
  /// In en, this message translates to:
  /// **'Correction approved.'**
  String get correctionApprovedDone;

  /// No description provided for @correctionRejectedDone.
  ///
  /// In en, this message translates to:
  /// **'Correction rejected.'**
  String get correctionRejectedDone;

  /// No description provided for @correctionNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Your account can’t do this right now.'**
  String get correctionNotAllowed;

  /// No description provided for @correctionOwnRequest.
  ///
  /// In en, this message translates to:
  /// **'You can’t review your own request.'**
  String get correctionOwnRequest;

  /// No description provided for @correctionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This attendance day or request no longer exists.'**
  String get correctionNotFound;

  /// No description provided for @correctionNotClosed.
  ///
  /// In en, this message translates to:
  /// **'Only a closed day can be corrected.'**
  String get correctionNotClosed;

  /// No description provided for @correctionInvalidTimes.
  ///
  /// In en, this message translates to:
  /// **'The check-in must be on the work date and before the shift ends. The check-out must be after the check-in and before midnight.'**
  String get correctionInvalidTimes;

  /// No description provided for @correctionMissingCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Select a check-out time.'**
  String get correctionMissingCheckOut;

  /// No description provided for @correctionInvalidReason.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason of up to 2000 characters.'**
  String get correctionInvalidReason;

  /// No description provided for @correctionNoteTooLong.
  ///
  /// In en, this message translates to:
  /// **'The note can have at most 2000 characters.'**
  String get correctionNoteTooLong;

  /// No description provided for @correctionNoChange.
  ///
  /// In en, this message translates to:
  /// **'These are already the approved times.'**
  String get correctionNoChange;

  /// No description provided for @correctionAlreadyPending.
  ///
  /// In en, this message translates to:
  /// **'A request for this day is already waiting for review.'**
  String get correctionAlreadyPending;

  /// No description provided for @correctionAlreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'This request has already been reviewed.'**
  String get correctionAlreadyReviewed;

  /// No description provided for @correctionAttendanceChanged.
  ///
  /// In en, this message translates to:
  /// **'This day changed after the request was sent. Reject it so the employee can send a new one.'**
  String get correctionAttendanceChanged;

  /// No description provided for @correctionBusy.
  ///
  /// In en, this message translates to:
  /// **'A request is already being sent.'**
  String get correctionBusy;

  /// No description provided for @correctionNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach the server. Check the request’s status before trying again.'**
  String get correctionNetwork;

  /// No description provided for @correctionServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Corrections aren’t available right now.'**
  String get correctionServiceUnavailable;

  /// No description provided for @correctionUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get correctionUnknownError;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get adminDashboard;

  /// No description provided for @adminToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get adminToday;

  /// No description provided for @adminCheckedInNow.
  ///
  /// In en, this message translates to:
  /// **'Checked in now'**
  String get adminCheckedInNow;

  /// No description provided for @adminPastShiftEnd.
  ///
  /// In en, this message translates to:
  /// **'Still checked in after the shift end'**
  String get adminPastShiftEnd;

  /// No description provided for @adminSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, username or code'**
  String get adminSearchHint;

  /// No description provided for @adminStaleData.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t refresh. Showing earlier data.'**
  String get adminStaleData;

  /// No description provided for @adminLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the dashboard.'**
  String get adminLoadFailed;

  /// No description provided for @adminNoEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get adminNoEmployees;

  /// No description provided for @adminInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminInactive;

  /// No description provided for @adminFirstSignInPending.
  ///
  /// In en, this message translates to:
  /// **'Hasn’t signed in yet'**
  String get adminFirstSignInPending;

  /// No description provided for @adminSince.
  ///
  /// In en, this message translates to:
  /// **'Since {time}'**
  String adminSince(String time);

  /// No description provided for @adminHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attendance days yet.'**
  String get adminHistoryEmpty;

  /// No description provided for @adminAddEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add employee'**
  String get adminAddEmployee;

  /// No description provided for @adminRequests.
  ///
  /// In en, this message translates to:
  /// **'Cash requests'**
  String get adminRequests;

  /// No description provided for @adminFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get adminFullName;

  /// No description provided for @adminInitialPassword.
  ///
  /// In en, this message translates to:
  /// **'First password'**
  String get adminInitialPassword;

  /// No description provided for @adminInitialPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 12 characters. The employee changes it at first sign-in.'**
  String get adminInitialPasswordHint;

  /// No description provided for @adminCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get adminCreateAccount;

  /// No description provided for @adminAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created for {name}. They sign in with this email and the first password, then choose a new password.'**
  String adminAccountCreated(String name);

  /// No description provided for @adminAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another employee'**
  String get adminAddAnother;

  /// No description provided for @adminSchedulesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the work schedules.'**
  String get adminSchedulesLoadFailed;

  /// No description provided for @adminInvalidFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter 1–200 characters.'**
  String get adminInvalidFullName;

  /// No description provided for @adminInvalidUsername.
  ///
  /// In en, this message translates to:
  /// **'3–64 lowercase letters, digits, dots, dashes or underscores, starting with a letter or digit.'**
  String get adminInvalidUsername;

  /// No description provided for @adminInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get adminInvalidEmail;

  /// No description provided for @adminInvalidEmployeeCode.
  ///
  /// In en, this message translates to:
  /// **'2–50 letters, digits, dashes or underscores.'**
  String get adminInvalidEmployeeCode;

  /// No description provided for @adminInvalidSchedule.
  ///
  /// In en, this message translates to:
  /// **'Choose a work schedule.'**
  String get adminInvalidSchedule;

  /// No description provided for @adminInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters (at most 72 bytes).'**
  String get adminInvalidPassword;

  /// No description provided for @adminNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only an active administrator can do this.'**
  String get adminNotAllowed;

  /// No description provided for @adminAccountConflict.
  ///
  /// In en, this message translates to:
  /// **'This username, employee code or email is already used.'**
  String get adminAccountConflict;

  /// No description provided for @adminInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'The server refused these details. Check them and try again.'**
  String get adminInvalidInput;

  /// No description provided for @adminOutcomeUnknown.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t confirm the result. Try again: the same request is never applied twice.'**
  String get adminOutcomeUnknown;

  /// No description provided for @adminTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get adminTooManyRequests;

  /// No description provided for @adminOwnRequest.
  ///
  /// In en, this message translates to:
  /// **'You can’t review your own request.'**
  String get adminOwnRequest;

  /// No description provided for @adminAlreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'This request has already been reviewed.'**
  String get adminAlreadyReviewed;

  /// No description provided for @adminNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists.'**
  String get adminNotFound;

  /// No description provided for @adminBusy.
  ///
  /// In en, this message translates to:
  /// **'This is already being sent.'**
  String get adminBusy;

  /// No description provided for @adminNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach the server. Check your connection and try again.'**
  String get adminNetwork;

  /// No description provided for @adminWebOriginBlocked.
  ///
  /// In en, this message translates to:
  /// **'The account service refused this web address, so no account was created. Use the mobile app, or allow this address in the service’s settings.'**
  String get adminWebOriginBlocked;

  /// No description provided for @adminServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This isn’t available right now.'**
  String get adminServiceUnavailable;

  /// No description provided for @adminUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get adminUnknownError;

  /// No description provided for @adminCashRequest.
  ///
  /// In en, this message translates to:
  /// **'Cash request'**
  String get adminCashRequest;

  /// No description provided for @adminSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get adminSubmitted;

  /// No description provided for @adminOvertimeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String adminOvertimeHours(int hours);

  /// No description provided for @adminRequestsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Cash requests from employees will appear here.'**
  String get adminRequestsEmptyMessage;

  /// No description provided for @adminApproveRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve this request?'**
  String get adminApproveRequestTitle;

  /// No description provided for @adminRejectRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this request?'**
  String get adminRejectRequestTitle;

  /// No description provided for @adminRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved.'**
  String get adminRequestApproved;

  /// No description provided for @adminRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected.'**
  String get adminRequestRejected;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;
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
