/// Why a check-in, check-out or loading today's attendance failed.
///
/// It is an [Exception] itself, like `LocationFailure`, so the repository
/// can simply `throw AttendanceFailure.alreadyCheckedIn;`.
enum AttendanceFailure implements Exception {
  /// Signed out, or the account is inactive or must change its password.
  accountNotReady,
  noSchedule,

  /// Today is not a working day in the employee's schedule.
  notWorkingDay,

  /// The shift has ended; the database no longer accepts a check-in today.
  checkInClosed,
  alreadyCheckedIn,
  notCheckedIn,
  alreadyCheckedOut,

  /// The shift ended without a check-out, so the day was closed
  /// automatically. The database records no check-out after that.
  closedAutomatically,

  /// The business date changed during the request (around midnight).
  workDateChanged,
  invalidLocation,
  selfieMissing,
  selfieUploadFailed,

  /// Another check-in or check-out is already being saved.
  busy,

  /// The request may or may not have been saved, and reloading to find out
  /// also failed. Reload before trying again.
  outcomeUnknown,
  network,

  /// The database is missing a function this app needs (not migrated yet).
  serviceUnavailable,
  unknown;

  /// The attendance on the server is not what the app showed; reload it.
  bool get needsReload => switch (this) {
    alreadyCheckedIn ||
    notCheckedIn ||
    alreadyCheckedOut ||
    checkInClosed ||
    closedAutomatically ||
    notWorkingDay ||
    workDateChanged ||
    outcomeUnknown => true,
    _ => false,
  };
}
