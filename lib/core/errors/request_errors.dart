/// Why loading or sending an overtime or cash request failed.
///
/// An [Exception] itself, like `AttendanceFailure`, so repositories can
/// simply `throw RequestFailure.duplicate;`.
enum RequestFailure implements Exception {
  /// Signed out, or the account is inactive or must change its password.
  accountNotReady,

  /// An overtime request for the same day and period is already pending or
  /// approved.
  duplicate,
  invalidHours,
  invalidAmount,
  invalidCurrency,
  invalidReason,
  invalidInput,

  /// A request is already being sent.
  busy,

  /// The request may or may not have been saved, and reloading to find out
  /// also failed. Reload before sending it again.
  outcomeUnknown,
  network,

  /// The database is missing a function this app needs.
  serviceUnavailable,
  unknown;

  /// Maps a database error from the request tables and functions.
  static RequestFailure fromDatabase(String? code, String message) {
    switch (code) {
      // require_actor: no active, password-ready account.
      case '42501':
        return accountNotReady;
      // overtime_one_live_period: one pending or approved request per
      // employee, day and period.
      case '23505':
        return duplicate;
      // Check constraints name the column they guard.
      case '23514':
        if (message.contains('hours')) return invalidHours;
        if (message.contains('amount')) return invalidAmount;
        if (message.contains('currency')) return invalidCurrency;
        if (message.contains('reason')) return invalidReason;
        return invalidInput;
      // request_expense_advance: more than two decimal places.
      case '22023':
        return message.startsWith('Amount') ? invalidAmount : invalidInput;
      // Not a valid number or date, or out of range.
      case '22P02' || '22003' || '22007' || '22008':
        return invalidInput;
      // No profile row for this account.
      case '23503':
        return accountNotReady;
      // Function or table not found in the API.
      case 'PGRST202' || 'PGRST205':
        return serviceUnavailable;
      // Expired or invalid access token.
      case 'PGRST301' || 'PGRST303':
        return accountNotReady;
    }
    return unknown;
  }
}
