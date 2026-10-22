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
}
