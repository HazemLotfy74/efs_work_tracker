/// A pending cash (expense advance) request, with who sent it.
///
/// Overtime has no requests: it is calculated from worked time.
class AdminRequestEntity {
  const AdminRequestEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.reason,
    required this.createdAt,
    required this.amount,
    required this.currency,
    this.assignedReviewerId,
  });

  /// The `p_kind` of `review_request` for these requests.
  static const reviewKind = 'expense_advance';

  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String reason;
  final DateTime createdAt;
  final num amount;
  final String currency;

  /// The employee an admin asked to decide it; `null` when none.
  final String? assignedReviewerId;
}
