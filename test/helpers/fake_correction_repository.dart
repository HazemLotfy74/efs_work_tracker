import 'dart:async';

import 'package:efs_work_tracker/app/features/attendance_correction/domain/entities/correction_request_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/domain/repositories/correction_repository.dart';
import 'package:efs_work_tracker/core/errors/correction_errors.dart';

/// In-memory [CorrectionRepository] for tests. Set [failure] to make the
/// next calls fail, [gate] to hold a write until it completes.
class FakeCorrectionRepository implements CorrectionRepository {
  FakeCorrectionRepository({List<CorrectionRequestEntity>? requests})
    : requests = requests ?? [];

  /// The requests [getForAttendance] and [getPendingForReview] return.
  List<CorrectionRequestEntity> requests;
  CorrectionFailure? failure;
  Completer<void>? gate;
  int loads = 0;

  final submitted =
      <
        ({
          String attendanceId,
          DateTime checkIn,
          DateTime checkOut,
          String reason,
        })
      >[];
  final reviews = <({String id, bool approve, String? note})>[];

  @override
  Future<List<CorrectionRequestEntity>> getForAttendance(
    String attendanceId,
  ) async {
    loads++;
    if (failure case final failure?) throw failure;
    return [
      for (final request in requests)
        if (request.attendanceId == attendanceId) request,
    ];
  }

  @override
  Future<void> submit({
    required String attendanceId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  }) async {
    await gate?.future;
    if (failure case final failure?) throw failure;
    submitted.add((
      attendanceId: attendanceId,
      checkIn: checkIn,
      checkOut: checkOut,
      reason: reason,
    ));
  }

  @override
  Future<List<CorrectionRequestEntity>> getPendingForReview() async {
    loads++;
    if (failure case final failure?) throw failure;
    return [
      for (final request in requests)
        if (request.isPending) request,
    ];
  }

  @override
  Future<void> review(
    String requestId, {
    required bool approve,
    String? note,
  }) async {
    await gate?.future;
    if (failure case final failure?) throw failure;
    reviews.add((id: requestId, approve: approve, note: note));
    requests = [
      for (final request in requests)
        if (request.id != requestId) request,
    ];
  }
}
