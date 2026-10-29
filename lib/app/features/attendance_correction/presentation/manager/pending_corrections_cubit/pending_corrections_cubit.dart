import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/correction_errors.dart';
import '../../../domain/entities/correction_request_entity.dart';
import '../../../domain/repositories/correction_repository.dart';

part 'pending_corrections_state.dart';

/// The admin's queue of pending correction requests.
///
/// Showing it is not the security boundary: `review_request` itself
/// refuses non-admins and an admin's own requests.
class PendingCorrectionsCubit extends Cubit<PendingCorrectionsState> {
  PendingCorrectionsCubit(this._repository)
    : super(const PendingCorrectionsLoading());

  final CorrectionRepository _repository;

  /// Only the newest load may emit.
  int _loadId = 0;

  /// Loads the queue; a failed refresh keeps the list that is shown.
  Future<void> load() async {
    final loadId = ++_loadId;
    if (state is! PendingCorrectionsLoaded) {
      emit(const PendingCorrectionsLoading());
    }
    try {
      final requests = await _repository.getPendingForReview();
      if (isClosed || loadId != _loadId) return;
      final reviewing = switch (state) {
        PendingCorrectionsLoaded(:final reviewing) => reviewing,
        _ => const <String>{},
      };
      emit(PendingCorrectionsLoaded(requests, reviewing: reviewing));
    } catch (_) {
      if (isClosed || loadId != _loadId) return;
      if (state is! PendingCorrectionsLoaded) {
        emit(const PendingCorrectionsError());
      }
    }
  }

  /// Approves or rejects one request; returns why it failed, or `null`.
  /// A reviewed request leaves the queue.
  Future<CorrectionFailure?> review(
    String requestId, {
    required bool approve,
    String? note,
  }) async {
    final current = state;
    if (current is! PendingCorrectionsLoaded) return CorrectionFailure.busy;
    if (current.reviewing.contains(requestId)) return CorrectionFailure.busy;
    emit(current.copyWith(reviewing: {...current.reviewing, requestId}));

    CorrectionFailure? failure;
    try {
      await _repository.review(requestId, approve: approve, note: note);
    } catch (error) {
      failure = error is CorrectionFailure ? error : CorrectionFailure.unknown;
    }
    if (isClosed) return failure;

    final latest = state;
    if (latest is PendingCorrectionsLoaded) {
      emit(
        latest.copyWith(
          requests: failure == null
              ? [
                  for (final request in latest.requests)
                    if (request.id != requestId) request,
                ]
              : latest.requests,
          reviewing: {...latest.reviewing}..remove(requestId),
        ),
      );
    }
    // Reviewed elsewhere, or the answer was lost: show the server's queue.
    if (failure != null && failure.needsReload) await load();
    return failure;
  }
}
