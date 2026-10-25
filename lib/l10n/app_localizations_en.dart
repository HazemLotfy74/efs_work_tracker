// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get notCheckedIn => 'Not Checked In';

  @override
  String get currentLocalTime => 'Current Local Time';

  @override
  String get checkInNow => 'Check In Now';

  @override
  String officialShift(String start, String end) {
    return 'Official shift · $start–$end';
  }

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get checkedIn => 'Checked In';

  @override
  String get home => 'Home';

  @override
  String get attendance => 'Attendance';

  @override
  String get viewDetails => 'View Details';

  @override
  String get todayOverview => 'Today\'s Overview';

  @override
  String get recorded => 'Recorded';

  @override
  String get lateness => 'Lateness';

  @override
  String get earlyLeave => 'Early Leave';

  @override
  String get approvedOT => 'Approved OT';

  @override
  String get today => 'Today';

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
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get history => 'History';

  @override
  String get alerts => 'Alerts';

  @override
  String get needToWorkLater => 'Need to work later?';

  @override
  String get requestOverTime => 'Request Overtime For Manager Approval';

  @override
  String get needCash => 'Need a cash advance?';

  @override
  String get sendRequest => 'Send a request to your administrator';

  @override
  String get attendanceDetails => 'Attendance Details';

  @override
  String get needsReview => 'Needs Review';

  @override
  String get automaticClosed => 'Automatically closed';

  @override
  String get noEmployee => 'No employee checkout recorded';

  @override
  String get noCheckout =>
      'No checkout selfie or GPS location exists for this event';

  @override
  String get workSummary => 'Work summary';

  @override
  String get attendanceEvents => 'Attendance events';

  @override
  String get withinGracePeriod => 'Within grace period';

  @override
  String get checkIn => 'Check-in';

  @override
  String get selfieAndGps => 'Selfie and GPS evidence captured';

  @override
  String get systemGenerated => 'System generated';

  @override
  String get autoClosed => 'Auto-closed';

  @override
  String get noLocationOrSelfie => 'No location or selfie captured';

  @override
  String get flaggedForAdmin => 'Flagged for administrative review';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signWithAccount =>
      'Sign in with your company account to continue.';

  @override
  String get workEmail => 'Work email';

  @override
  String get password => 'Password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get signIn => 'Sign In';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get backToSignIn => 'Back to Sign In';

  @override
  String get accountRecovery => 'Account recovery';

  @override
  String get resetPassword => 'Reset your password';

  @override
  String get enterRecEmailToSendLink =>
      'Enter your work email and we’ll send secure recovery instructions.';

  @override
  String get sendRecLink => 'Send recovery link';

  @override
  String get attendanceMadeClear =>
      'Attendance made clear, wherever work happens.';

  @override
  String get secureAccess => 'Secure access to your WorkTrack account.';

  @override
  String get contactYourAdmin =>
      'Contact your administrator if you no longer have access to your work email.';

  @override
  String get checkInPage => 'Check in';

  @override
  String get prepare => 'Prepare';

  @override
  String get location => 'Location';

  @override
  String get selfie => 'Selfie';

  @override
  String get review => 'Review';

  @override
  String get readyToStart => 'Ready To Start?';

  @override
  String get captureLocAndSelfie =>
      'We’ll capture a current selfie and GPS location as attendance evidence.';

  @override
  String get date => 'Date';

  @override
  String get currentTime => 'Current Time';

  @override
  String get shift => 'Shift';

  @override
  String get yourSelfie =>
      'Your selfie and location are used only to verify this attendance event.';

  @override
  String get continueTo => 'Continue';

  @override
  String get verifyYourLocation => 'Verify Your Location';

  @override
  String get keepYourLocation =>
      'Keep location services on while we securely capture your current position.';

  @override
  String get locationVerified => 'Location verified';

  @override
  String get havingTrouble => 'Having trouble with location?';

  @override
  String get useThisLoc => 'Use this location';

  @override
  String get takeQuickSelfie => 'Take a quick selfie';

  @override
  String get positionYourFace =>
      'Position your face inside the guide and use a well-lit area.';

  @override
  String get reviewAndConfirm => 'Review & confirm';

  @override
  String get makeSure =>
      'Make sure these details are correct before submitting.';

  @override
  String get selfieReady => 'Selfie ready';

  @override
  String get attendanceEvidence => 'Attendance evidence';

  @override
  String get captureAndContinue => 'Capture & continue';

  @override
  String get confirmCheckIn => 'Confirm check-in';

  @override
  String get youAreAllSet => 'You’re all set!';

  @override
  String get yourSessionIsNowActive =>
      'Your attendance session is now active. Have a productive day.';

  @override
  String get confirmedAt => 'Confirmed At';

  @override
  String get selfieSubmitted => 'Selfie submitted';

  @override
  String get returnToHome => 'Return to home';

  @override
  String get locating => 'Finding your location…';

  @override
  String get currentLocation => 'Current location';

  @override
  String locationAccuracy(int meters, String time) {
    return 'Accuracy · $meters meters · Captured at $time';
  }

  @override
  String get coordinatesPrivate => 'Exact coordinates are kept private.';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get locationServiceDisabled =>
      'Location services are turned off. Turn them on to continue.';

  @override
  String get locationPermissionDenied =>
      'Location permission is needed to verify your attendance.';

  @override
  String get locationPermissionDeniedForever =>
      'Location access is blocked. Allow it in the app settings to continue.';

  @override
  String get locationTimeout =>
      'We couldn\'t get a GPS fix in time. Move to an open area and try again.';

  @override
  String get locationUnknownError =>
      'Something went wrong while getting your location.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get openSettings => 'Open settings';

  @override
  String get clickHereToUpload => 'Click here to upload your selfie';

  @override
  String stepOf(int current, int total) {
    return '$current of $total';
  }

  @override
  String get checkInTime => 'Check-in time';

  @override
  String capturedAt(String time) {
    return 'Captured at $time';
  }

  @override
  String get checkOutPage => 'Check out';

  @override
  String get checkOutTime => 'Check-out time';

  @override
  String get confirmCheckOut => 'Confirm check-out';

  @override
  String get checkedOut => 'Checked Out';

  @override
  String get workdayRecorded => 'Workday recorded';

  @override
  String get checkoutRecorded => 'Your checkout was recorded successfully.';

  @override
  String get checkoutRecordedEarly =>
      'Your checkout was recorded successfully. The early departure has been flagged for review.';

  @override
  String get finalDuration => 'Final duration';

  @override
  String get viewAttendanceDetails => 'View attendance details';

  @override
  String get recordedDuration => 'Recorded duration';

  @override
  String get earlyDeparture => 'Early departure';

  @override
  String earlyDepartureMessage(String duration) {
    return 'This checkout is $duration before shift end and may require review.';
  }

  @override
  String get elapsedWorkingTime => 'Elapsed working time';

  @override
  String get totalWorkingTime => 'Total working time';

  @override
  String get shiftEnds => 'Shift ends';

  @override
  String get live => 'LIVE';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get saveAttendanceFailed =>
      'Couldn\'t save your attendance. Check your connection and try again.';

  @override
  String get attendanceLoadFailed => 'Couldn\'t load today\'s attendance.';

  @override
  String verifiedAccuracy(int meters) {
    return 'Verified · ${meters}m';
  }
}
