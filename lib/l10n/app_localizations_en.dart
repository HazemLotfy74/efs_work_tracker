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
  String get approvedOT => 'Overtime';

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
    return 'This checkout is $duration short of 8 regular hours and may require review.';
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

  @override
  String get overTimeRequests => 'Overtime requests';

  @override
  String get approvedThisMonth => 'Approved this month';

  @override
  String get pendingDecision => 'Awaiting decision';

  @override
  String get pendingApproval => 'Pending approval';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get recentRequests => 'Recent requests';

  @override
  String get request => 'Request';

  @override
  String get all => 'All';

  @override
  String get createOverTimeRequest => 'Create Overtime Request';

  @override
  String get requestOverTimePage => 'Request Overtime For Manager Approval';

  @override
  String get approvalRequired => 'Approval required';

  @override
  String get workingAfter4 =>
      'Working after 4:00 PM does not automatically mean overtime is approved.';

  @override
  String get requestedScheduled => 'Requested schedule';

  @override
  String get startTime => 'Start time';

  @override
  String get endTome => 'End time';

  @override
  String get requestedDuration => 'Requested duration';

  @override
  String get reasonForOverTime => 'Reason for overtime';

  @override
  String get requestSummary => 'Request summary';

  @override
  String get approvalStatus => 'Approval status';

  @override
  String get requestSubmitted => 'Request submitted';

  @override
  String get pendingRequests => 'Pending requests';

  @override
  String get cashRequestReview =>
      'Cash requests are reviewed by your company administrator.';

  @override
  String get requestHistory => 'Request history';

  @override
  String get newCashRequest => 'New cash request';

  @override
  String get approvalRequiredForCash => 'Administrator approval required';

  @override
  String get submittingApproval =>
      'Submitting this form does not guarantee that the request will be approved.';

  @override
  String get requestAmount => 'Requested amount';

  @override
  String get reasonForRequest => 'Reason for request';

  @override
  String get employee => 'Employee';

  @override
  String get amount => 'Amount';

  @override
  String get statusAfterRequest => 'Status after sending';

  @override
  String get sendToAdmin => 'Send to administrator';

  @override
  String get cashRequests => 'Cash requests';

  @override
  String get overtimeBefore4pm => 'Before 4:00 PM';

  @override
  String get overtimeAfter4pm => 'After 4:00 PM';

  @override
  String get overtimePeriod => 'Period';

  @override
  String get fewerHours => 'Fewer hours';

  @override
  String get moreHours => 'More hours';

  @override
  String get overtimeLoadFailed => 'Couldn’t load your overtime requests.';

  @override
  String get overtimeEmptyTitle => 'No overtime requests';

  @override
  String get overtimeEmptyMessage =>
      'Overtime requests you send will appear here.';

  @override
  String get overtimeSubmittedMessage =>
      'Your request was sent to your administrator. Overtime counts only after an administrator approves it.';

  @override
  String get backToRequests => 'Back to requests';

  @override
  String get requestDetails => 'Request details';

  @override
  String get requestNotFound => 'This request was not found.';

  @override
  String get submittedAt => 'Submitted';

  @override
  String get reviewedAt => 'Reviewed';

  @override
  String get reviewNote => 'Administrator note';

  @override
  String get cashLoadFailed => 'Couldn’t load your cash requests.';

  @override
  String get cashEmptyTitle => 'No cash requests';

  @override
  String get cashEmptyMessage => 'Cash requests you send will appear here.';

  @override
  String get cashSubmittedMessage =>
      'Request sent. It is pending until your administrator reviews it.';

  @override
  String get cashAmountRequired => 'Enter the amount.';

  @override
  String get cashAmountInvalid =>
      'Enter an amount greater than 0 with at most 2 decimal places.';

  @override
  String moneyAmount(String amount, String currency) {
    return '$amount $currency';
  }

  @override
  String get requestReasonRequired => 'Enter a reason.';

  @override
  String get requestReasonTooLong =>
      'The reason can have at most 2000 characters.';

  @override
  String get requestReasonInvalid => 'Enter a reason of up to 2000 characters.';

  @override
  String get requestAccountNotReady =>
      'Your account can’t send requests right now. Sign in again or contact your administrator.';

  @override
  String get overtimeDuplicate =>
      'You already have a pending or approved overtime request for this day and period.';

  @override
  String get overtimeHoursInvalid => 'Choose at least 1 hour.';

  @override
  String get requestInvalidCurrency => 'This currency isn’t supported.';

  @override
  String get requestInvalidInput =>
      'Some details aren’t valid. Check them and try again.';

  @override
  String get requestBusy => 'A request is already being sent.';

  @override
  String get requestOutcomeUnknown =>
      'We couldn’t confirm whether your request was sent. Check your connection, then tap send again: the app checks first and won’t send it twice.';

  @override
  String get requestNetworkError =>
      'Can’t reach the server. Your request was not sent. Check your connection and try again.';

  @override
  String get requestServiceUnavailable =>
      'Requests aren’t available right now.';

  @override
  String get requestUnknownError => 'Something went wrong. Please try again.';

  @override
  String get authInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authAccountUnavailable =>
      'This account is not available. Contact your administrator.';

  @override
  String get authEmailNotConfirmed =>
      'Your email address has not been confirmed yet.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get authWeakPassword =>
      'This password doesn’t meet the security rules. Choose a stronger one.';

  @override
  String get authSamePassword =>
      'Choose a password different from your current one.';

  @override
  String get authReauthenticationNeeded =>
      'For your security, sign in again before changing your password.';

  @override
  String get authPasswordCompletionPending =>
      'Your password may have changed. Sign in with the new password and set another one to finish.';

  @override
  String get authSessionExpired =>
      'Your session has ended. Please sign in again.';

  @override
  String get authNetworkError =>
      'Can’t reach the server. Check your connection and try again.';

  @override
  String get authUnknownError => 'Something went wrong. Please try again.';

  @override
  String get accountSetup => 'Account setup';

  @override
  String get changePasswordTitle => 'Set a new password';

  @override
  String get changePasswordSubtitle =>
      'For your security, choose a new password before you continue.';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordRules => 'Use at least 12 characters.';

  @override
  String get savePassword => 'Save password';

  @override
  String get signOut => 'Sign out';

  @override
  String get recoveryLinkSent =>
      'If this email belongs to an account, recovery instructions are on their way.';

  @override
  String get attendanceAccountNotReady =>
      'Your account can’t record attendance right now. Sign in again or contact your administrator.';

  @override
  String get attendanceNoSchedule =>
      'No work schedule is assigned to your account. Contact your administrator.';

  @override
  String get attendanceNotWorkingDay =>
      'Today is not a working day in your schedule.';

  @override
  String get attendanceCheckInClosed =>
      'Today’s shift has ended, so check-in is closed.';

  @override
  String get attendanceAlreadyCheckedIn => 'You have already checked in today.';

  @override
  String get attendanceNotCheckedIn =>
      'There is no check-in to check out from today.';

  @override
  String get attendanceAlreadyCheckedOut =>
      'Your check-out was already recorded.';

  @override
  String get attendanceClosedAutomatically =>
      'Your day was already closed automatically, so a check-out can’t be recorded. An administrator has to review this day.';

  @override
  String get regularHoursEnd => '8 hours at';

  @override
  String get attendanceWorkDateChanged =>
      'The work day changed while saving. Please try again.';

  @override
  String get attendanceInvalidLocation =>
      'Your location couldn’t be verified. Go back to the Location step and try again.';

  @override
  String get attendanceSelfieMissing =>
      'Your selfie wasn’t received. Take it again and retry.';

  @override
  String get attendanceSelfieUploadFailed =>
      'Your selfie couldn’t be uploaded. Check your connection and try again.';

  @override
  String get attendanceBusy => 'Your attendance is already being saved.';

  @override
  String get attendanceOutcomeUnknown =>
      'We couldn’t confirm whether your attendance was saved. Check the home screen before trying again.';

  @override
  String get attendanceServiceUnavailable =>
      'Attendance is being updated. Please try again later.';

  @override
  String get attendanceUnknownError =>
      'Something went wrong with your attendance. Please try again.';

  @override
  String get noShiftToday => 'No shift today';

  @override
  String get closedAutomatically => 'Closed automatically';

  @override
  String get closedAt => 'Closed at';

  @override
  String autoClosedNote(String time) {
    return 'Your day was closed automatically at $time without a check-out, so your hours are not confirmed and an administrator has to review them. If you worked later, send an overtime request.';
  }

  @override
  String closesBeforeRegularHours(String time) {
    return 'Attendance closes automatically at $time, before your 8 regular hours are complete. Check out before then.';
  }

  @override
  String get notConfirmed => 'Not confirmed';

  @override
  String get regularHours => 'Regular hours';

  @override
  String get observedOvertime => 'Overtime';

  @override
  String get observedOvertimeNote =>
      'Counted automatically: every minute worked beyond 8 hours.';

  @override
  String get inProgress => 'In progress';

  @override
  String get attendanceNotFound => 'This attendance record was not found.';

  @override
  String get historyEmptyTitle => 'No attendance yet';

  @override
  String get historyEmptyMessage => 'Your attendance days will appear here.';

  @override
  String get historyLoadFailed => 'Couldn’t load your attendance history.';

  @override
  String lateMinutes(int minutes) {
    return '$minutes min late';
  }

  @override
  String get onTime => 'On time';

  @override
  String get employeeCode => 'Employee code';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get role => 'Role';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleEmployee => 'Employee';

  @override
  String get workSchedule => 'Work schedule';

  @override
  String get requestCorrection => 'Request correction';

  @override
  String get correctionTitle => 'Correct attendance';

  @override
  String get correctionIntro =>
      'This day was closed automatically, so its hours aren’t confirmed. Enter the times you actually worked; an administrator will review them.';

  @override
  String get correctionCheckIn => 'Check-in time';

  @override
  String get correctionCheckOut => 'Check-out time';

  @override
  String get correctionPickTime => 'Select time';

  @override
  String get correctionReason => 'Reason';

  @override
  String get correctionReasonHint => 'Why is the check-out missing?';

  @override
  String correctionTimezoneNote(String timezone) {
    return 'Times are in company time ($timezone).';
  }

  @override
  String get correctionSubmit => 'Send request';

  @override
  String get correctionSubmitted => 'Correction request sent.';

  @override
  String get correctionRequest => 'Correction request';

  @override
  String get correctionProposedTimes => 'Proposed times';

  @override
  String get correctionReviewNote => 'Reviewer note';

  @override
  String get correctionLoadFailed => 'Couldn’t load the correction requests.';

  @override
  String get correctionResubmit => 'You can send a new request.';

  @override
  String get correctionPendingNote =>
      'An administrator will review this request.';

  @override
  String get adminCorrections => 'Correction requests';

  @override
  String get adminCorrectionsEmptyTitle => 'No pending requests';

  @override
  String get adminCorrectionsEmptyMessage =>
      'Correction requests from employees will appear here.';

  @override
  String get adminCorrectionsLoadFailed =>
      'Couldn’t load the correction requests.';

  @override
  String get correctionRecordedCheckIn => 'Recorded check-in';

  @override
  String get correctionApprove => 'Approve';

  @override
  String get correctionReject => 'Reject';

  @override
  String get correctionApproveTitle => 'Approve this correction?';

  @override
  String get correctionRejectTitle => 'Reject this correction?';

  @override
  String get correctionApproveMessage =>
      'The proposed times become the confirmed hours of this day.';

  @override
  String get correctionRejectMessage =>
      'The day stays unconfirmed. The employee can send a new request.';

  @override
  String get correctionNoteOptional => 'Note (optional)';

  @override
  String get correctionCancel => 'Cancel';

  @override
  String get correctionApprovedDone => 'Correction approved.';

  @override
  String get correctionRejectedDone => 'Correction rejected.';

  @override
  String get correctionNotAllowed => 'Your account can’t do this right now.';

  @override
  String get correctionOwnRequest => 'You can’t review your own request.';

  @override
  String get correctionNotFound =>
      'This attendance day or request no longer exists.';

  @override
  String get correctionNotClosed => 'Only a closed day can be corrected.';

  @override
  String get correctionInvalidTimes =>
      'The check-in must be on the work date and before the shift ends. The check-out must be after the check-in and before midnight.';

  @override
  String get correctionMissingCheckOut => 'Select a check-out time.';

  @override
  String get correctionInvalidReason =>
      'Enter a reason of up to 2000 characters.';

  @override
  String get correctionNoteTooLong =>
      'The note can have at most 2000 characters.';

  @override
  String get correctionNoChange => 'These are already the approved times.';

  @override
  String get correctionAlreadyPending =>
      'A request for this day is already waiting for review.';

  @override
  String get correctionAlreadyReviewed =>
      'This request has already been reviewed.';

  @override
  String get correctionAttendanceChanged =>
      'This day changed after the request was sent. Reject it so the employee can send a new one.';

  @override
  String get correctionBusy => 'A request is already being sent.';

  @override
  String get correctionNetwork =>
      'Couldn’t reach the server. Check the request’s status before trying again.';

  @override
  String get correctionServiceUnavailable =>
      'Corrections aren’t available right now.';

  @override
  String get correctionUnknownError =>
      'Something went wrong. Please try again.';

  @override
  String get adminDashboard => 'Admin dashboard';

  @override
  String get adminToday => 'Today';

  @override
  String get adminCheckedInNow => 'Checked in now';

  @override
  String get adminPastShiftEnd => 'Still checked in after the shift end';

  @override
  String get adminSearchHint => 'Search by name, username or code';

  @override
  String get adminStaleData => 'Couldn’t refresh. Showing earlier data.';

  @override
  String get adminLoadFailed => 'Couldn’t load the dashboard.';

  @override
  String get adminNoEmployees => 'No employees found';

  @override
  String get adminInactive => 'Inactive';

  @override
  String get adminFirstSignInPending => 'Hasn’t signed in yet';

  @override
  String adminSince(String time) {
    return 'Since $time';
  }

  @override
  String get adminHistoryEmpty => 'No attendance days yet.';

  @override
  String get adminAddEmployee => 'Add employee';

  @override
  String get adminRequests => 'Cash requests';

  @override
  String get adminFullName => 'Full name';

  @override
  String get adminInitialPassword => 'First password';

  @override
  String get adminInitialPasswordHint =>
      'At least 12 characters. The employee changes it at first sign-in.';

  @override
  String get adminCreateAccount => 'Create account';

  @override
  String adminAccountCreated(String name) {
    return 'Account created for $name. They sign in with this email and the first password, then choose a new password.';
  }

  @override
  String get adminAddAnother => 'Add another employee';

  @override
  String get adminSchedulesLoadFailed => 'Couldn’t load the work schedules.';

  @override
  String get adminInvalidFullName => 'Enter 1–200 characters.';

  @override
  String get adminInvalidUsername =>
      '3–64 lowercase letters, digits, dots, dashes or underscores, starting with a letter or digit.';

  @override
  String get adminInvalidEmail => 'Enter a valid email address.';

  @override
  String get adminInvalidEmployeeCode =>
      '2–50 letters, digits, dashes or underscores.';

  @override
  String get adminInvalidSchedule => 'Choose a work schedule.';

  @override
  String get adminInvalidPassword =>
      'Use at least 12 characters (at most 72 bytes).';

  @override
  String get adminNotAllowed => 'Only an active administrator can do this.';

  @override
  String get adminAccountConflict =>
      'This username, employee code or email is already used.';

  @override
  String get adminInvalidInput =>
      'The server refused these details. Check them and try again.';

  @override
  String get adminOutcomeUnknown =>
      'We couldn’t confirm the result. Try again: the same request is never applied twice.';

  @override
  String get adminTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get adminOwnRequest => 'You can’t review your own request.';

  @override
  String get adminAlreadyReviewed => 'This request has already been reviewed.';

  @override
  String get adminNotFound => 'This item no longer exists.';

  @override
  String get adminBusy => 'This is already being sent.';

  @override
  String get adminNetwork =>
      'Couldn’t reach the server. Check your connection and try again.';

  @override
  String get adminWebOriginBlocked =>
      'The account service refused this web address, so no account was created. Use the mobile app, or allow this address in the service’s settings.';

  @override
  String get adminServiceUnavailable => 'This isn’t available right now.';

  @override
  String get adminUnknownError => 'Something went wrong. Please try again.';

  @override
  String get adminCashRequest => 'Cash request';

  @override
  String get adminSubmitted => 'Submitted';

  @override
  String adminOvertimeHours(int hours) {
    return '$hours h';
  }

  @override
  String get adminRequestsEmptyMessage =>
      'Cash requests from employees will appear here.';

  @override
  String get adminApproveRequestTitle => 'Approve this request?';

  @override
  String get adminRejectRequestTitle => 'Reject this request?';

  @override
  String get adminRequestApproved => 'Request approved.';

  @override
  String get adminRequestRejected => 'Request rejected.';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';
}
