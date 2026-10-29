/// `status` of `overtime_requests` and `expense_advance_requests`.
///
/// Only an administrator changes it, through the database. The app reads
/// it and never sets it.
enum RequestStatus {
  pending,
  approved,
  rejected;

  /// Throws [FormatException] for any other value, so an unexpected status
  /// is shown as an error and never as approved.
  static RequestStatus fromName(String? name) => switch (name) {
    'pending' => pending,
    'approved' => approved,
    'rejected' => rejected,
    _ => throw FormatException('Unknown request status: $name'),
  };
}
