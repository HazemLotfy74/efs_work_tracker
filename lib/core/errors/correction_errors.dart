/// Why requesting, loading or reviewing an attendance correction failed.
///
/// Like `AttendanceFailure`, it is an [Exception] itself, so the repository
/// can simply `throw CorrectionFailure.alreadyPending;`.
enum CorrectionFailure implements Exception {
  /// Signed out, inactive, must change the password, or (when reviewing)
  /// not an administrator.
  notAllowed,

  /// An administrator can't review their own request.
  ownRequest,

  /// The attendance day or the request doesn't exist for this account.
  notFound,

  /// The day is still open; only a closed day can be corrected.
  notClosed,

  /// The check-in must be on the work date and before the shift ends; the
  /// check-out must be after the check-in and before midnight.
  invalidTimes,

  /// The app always sends a check-out, so the corrected hours are known.
  missingCheckOut,

  /// The reason must have 1–2000 characters.
  invalidReason,

  /// The review note can have at most 2000 characters.
  noteTooLong,

  /// The proposed times are the ones already approved.
  noChange,

  /// Only one pending request per attendance day.
  alreadyPending,

  /// Another administrator reviewed it first.
  alreadyReviewed,

  /// The day changed after the request was sent; reject it and ask the
  /// employee to send a new one.
  attendanceChanged,

  /// Another request is already being sent.
  busy,

  /// No answer; the request may or may not have been saved.
  network,

  /// The database is missing a function or table this app needs.
  serviceUnavailable,
  unknown;

  /// What the server holds is not what the app showed; reload it.
  bool get needsReload => switch (this) {
    notFound ||
    notClosed ||
    alreadyPending ||
    alreadyReviewed ||
    attendanceChanged ||
    network => true,
    _ => false,
  };
}
