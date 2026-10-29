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
