import '../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../cash_request/domain/entities/expense_advance_request_entity.dart';

/// The requests an admin assigned to the signed-in employee to decide.
///
/// The database shows a delegated reviewer only the request rows assigned
/// to them (not the requester's profile or attendance day) and lets them
/// decide only those, never their own. Every method throws an
/// `AdminFailure` (core/errors/admin_errors.dart).
abstract interface class AssignedReviewRepository {
  /// Pending cash requests assigned to me, oldest first.
  Future<List<ExpenseAdvanceRequestEntity>> getCash();

  /// Pending correction requests assigned to me, oldest first.
  Future<List<CorrectionRequestEntity>> getCorrections();

  /// `review_assigned_expense_advance`.
  Future<void> reviewCash(String id, {required bool approve, String? note});

  /// `review_assigned_attendance_correction`: an approval sets the day's
  /// confirmed times, exactly as an admin's approval does.
  Future<void> reviewCorrection(
    String id, {
    required bool approve,
    String? note,
  });
}
