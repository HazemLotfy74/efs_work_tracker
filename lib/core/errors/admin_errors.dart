/// Why an administrator action or an admin screen's load failed.
///
/// Like `AttendanceFailure`, it is an [Exception] itself.
enum AdminFailure implements Exception {
  /// Not an active administrator with a changed password. The database
  /// and the `employee-accounts` function refuse everyone else.
  notAllowed,

  /// Username, employee code, email or request already exists.
  accountConflict,

  /// The server refused the employee details or schedule.
  invalidInput,

  /// The account may or may not have been created; retry with the same
  /// details (the same request id is reused, so it is never created twice).
  outcomeUnknown,
  tooManyRequests,

  /// An administrator can't review their own request.
  ownRequest,

  /// Another administrator reviewed it first.
  alreadyReviewed,
  notFound,

  /// Correction times outside the day: check-in on the work date before the
  /// shift ends, check-out after it and before the close deadline.
  invalidTimes,

  /// A correction reason of 1–2000 characters is required.
  invalidReason,

  /// Only a closed day (checked out or closed automatically) is corrected.
  notClosed,

  /// The employee's own request for this day is waiting: review it first.
  pendingCorrection,

  /// These are already the corrected times.
  noChange,

  /// Admins can't correct their own attendance.
  ownAttendance,

  /// The day changed after the correction request was sent: reject it so
  /// the employee can send a new one.
  attendanceChanged,

  /// Another action is already being sent.
  busy,
  network,

  /// In a web browser, the `employee-accounts` function refused this
  /// page's address (CORS): it only accepts its configured web origin.
  /// Nothing was created.
  webOriginBlocked,

  /// A function or table this app needs is missing or not deployed.
  serviceUnavailable,
  unknown;

  /// What the server holds is not what the app showed; reload it.
  bool get needsReload => switch (this) {
    alreadyReviewed || notFound || network || outcomeUnknown => true,
    _ => false,
  };
}
