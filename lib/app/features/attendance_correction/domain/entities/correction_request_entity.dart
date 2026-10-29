/// `attendance_correction_requests.status`.
enum CorrectionStatus {
  pending,
  approved,
  rejected;

  /// Throws a [FormatException] for any other value.
  static CorrectionStatus fromName(Object? name) => switch (name) {
    'pending' => pending,
    'approved' => approved,
    'rejected' => rejected,
    _ => throw FormatException('Unknown correction status: $name'),
  };
}

/// An employee's request to set the real times of a day that was closed
/// automatically. An admin approves or rejects it; an approval sets the
/// day's effective times, which confirm its hours.
class CorrectionRequestEntity {
  const CorrectionRequestEntity({
    required this.id,
    required this.employeeId,
    required this.attendanceId,
    required this.proposedCheckIn,
    required this.proposedCheckOut,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewNote,
    this.employeeName,
    this.employeeCode,
    this.workDate,
    this.timezone,
    this.actualCheckIn,
  });

  final String id;
  final String employeeId;
  final String attendanceId;
  final DateTime proposedCheckIn;

  /// May be `null` in the database; requests sent by this app always have it.
  final DateTime? proposedCheckOut;
  final String reason;
  final CorrectionStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewNote;

  // Loaded only for the admin's review list.
  final String? employeeName;
  final String? employeeCode;

  /// The attendance day's work date (date only).
  final DateTime? workDate;

  /// The attendance day's IANA timezone, e.g. "Africa/Cairo".
  final String? timezone;

  /// The check-in the employee actually recorded.
  final DateTime? actualCheckIn;

  bool get isPending => status == CorrectionStatus.pending;
}
