import '../../../../../core/enums/request_status.dart';
import '../../domain/entities/expense_advance_request_entity.dart';

/// [ExpenseAdvanceRequestEntity] from an `expense_advance_requests` row.
abstract final class ExpenseAdvanceRequestModel {
  static const columns =
      'id, requested_amount, currency, reason, status, created_at, '
      'reviewed_at, review_note';

  /// Throws on a malformed row.
  static ExpenseAdvanceRequestEntity fromJson(Map<String, dynamic> json) {
    final reviewedAt = json['reviewed_at'] as String?;
    final amount = json['requested_amount'];
    return ExpenseAdvanceRequestEntity(
      id: json['id'] as String,
      // numeric may arrive as text when it is too precise for JSON numbers.
      amount: amount is num ? amount : num.parse(amount as String),
      currency: json['currency'] as String,
      reason: json['reason'] as String,
      status: RequestStatus.fromName(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: reviewedAt == null ? null : DateTime.parse(reviewedAt),
      reviewNote: json['review_note'] as String?,
    );
  }
}
