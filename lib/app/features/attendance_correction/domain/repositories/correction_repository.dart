import '../entities/correction_request_entity.dart';

/// Where attendance correction requests are loaded from and sent to.
///
/// `SupabaseCorrectionRepository` is the real one. Every method throws a
/// `CorrectionFailure` (core/errors/correction_errors.dart) on error.
abstract interface class CorrectionRepository {
  /// The signed-in employee's own requests for one attendance day, newest
  /// first.
  Future<List<CorrectionRequestEntity>> getForAttendance(String attendanceId);

  /// Asks an admin to set [checkIn] and [checkOut] on a closed day.
  Future<void> submit({
    required String attendanceId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  });

  /// Admin only: every employee's pending requests, oldest first, without
  /// the admin's own (which they can't review).
  Future<List<CorrectionRequestEntity>> getPendingForReview();

  /// Admin only: approves or rejects a pending request.
  Future<void> review(String requestId, {required bool approve, String? note});
}
