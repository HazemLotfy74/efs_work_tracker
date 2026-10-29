import '../entities/expense_advance_request_entity.dart';

/// The signed-in employee's cash advance requests. Every method throws a
/// `RequestFailure` when it fails.
abstract interface class ExpenseAdvanceRepository {
  /// The employee's own requests, newest first.
  Future<List<ExpenseAdvanceRequestEntity>> getRequests({int limit = 200});

  /// Sends [draft] for an administrator's decision. The request is always
  /// saved as pending.
  Future<ExpenseAdvanceRequestEntity> submit(ExpenseAdvanceDraft draft);

  /// After a send whose outcome is unknown: the request it saved, or `null`
  /// if it saved nothing and [draft] can be sent again.
  Future<ExpenseAdvanceRequestEntity?> findSubmitted(ExpenseAdvanceDraft draft);
}
