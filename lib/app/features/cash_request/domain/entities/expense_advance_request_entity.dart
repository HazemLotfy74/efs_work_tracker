import '../../../../../core/enums/request_status.dart';

/// A cash advance request as the employee filled it in, before it is sent.
class ExpenseAdvanceDraft {
  ExpenseAdvanceDraft({
    required this.amount,
    required String reason,
    this.currency = defaultCurrency,
  }) : reason = reason.trim();

  /// The database's default currency.
  static const defaultCurrency = 'EGP';

  /// More than 0, with at most two decimal places.
  final num amount;

  /// Trimmed, as the database stores it.
  final String reason;

  /// Three capital letters (ISO 4217).
  final String currency;

  @override
  bool operator ==(Object other) =>
      other is ExpenseAdvanceDraft &&
      other.amount == amount &&
      other.reason == reason &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, reason, currency);
}

/// One row of `expense_advance_requests`. Only an administrator changes
/// [status].
class ExpenseAdvanceRequestEntity {
  const ExpenseAdvanceRequestEntity({
    required this.id,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewNote,
  });

  final String id;
  final num amount;
  final String currency;
  final String reason;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewNote;

  /// Whether this request has the same content as [draft].
  bool matches(ExpenseAdvanceDraft draft) =>
      amount == draft.amount &&
      currency == draft.currency &&
      reason == draft.reason;
}
