import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/admin_errors.dart';
import '../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../cash_request/domain/entities/expense_advance_request_entity.dart';
import '../../domain/repositories/assigned_review_repository.dart';

sealed class AssignedReviewsState {
  const AssignedReviewsState();
}

final class AssignedReviewsLoading extends AssignedReviewsState {
  const AssignedReviewsLoading();
}

final class AssignedReviewsError extends AssignedReviewsState {
  const AssignedReviewsError(this.failure);
  final AdminFailure failure;
}

final class AssignedReviewsLoaded extends AssignedReviewsState {
  const AssignedReviewsLoaded({
    required this.cash,
    required this.corrections,
    this.reviewing = const {},
  });

  final List<ExpenseAdvanceRequestEntity> cash;
  final List<CorrectionRequestEntity> corrections;

  /// Ids whose decision is being sent.
  final Set<String> reviewing;

  bool get isEmpty => cash.isEmpty && corrections.isEmpty;
}

/// The pending requests assigned to the signed-in employee.
///
/// [loadCash] / [loadCorrections] follow the employee's permissions: a kind
/// they don't hold is not read at all.
class AssignedReviewsCubit extends Cubit<AssignedReviewsState> {
  AssignedReviewsCubit(
    this._repository, {
    required this.loadCash,
    required this.loadCorrections,
  }) : super(const AssignedReviewsLoading());

  final AssignedReviewRepository _repository;
  final bool loadCash;
  final bool loadCorrections;

  /// Only the newest load may emit.
  int _loadId = 0;

  /// Loads both lists; a failed refresh keeps what is shown.
  Future<void> load() async {
    final loadId = ++_loadId;
    if (state is! AssignedReviewsLoaded) emit(const AssignedReviewsLoading());
    try {
      final cash = loadCash
          ? await _repository.getCash()
          : const <ExpenseAdvanceRequestEntity>[];
      final corrections = loadCorrections
          ? await _repository.getCorrections()
          : const <CorrectionRequestEntity>[];
      if (isClosed || loadId != _loadId) return;
      emit(
        AssignedReviewsLoaded(
          cash: cash,
          corrections: corrections,
          reviewing: switch (state) {
            AssignedReviewsLoaded(:final reviewing) => reviewing,
            _ => const {},
          },
        ),
      );
    } on AdminFailure catch (failure) {
      if (isClosed || loadId != _loadId) return;
      if (state is! AssignedReviewsLoaded) emit(AssignedReviewsError(failure));
    }
  }

  /// Returns why it failed, or `null`. A decided request leaves the list.
  Future<AdminFailure?> reviewCash(
    String id, {
    required bool approve,
    String? note,
  }) => _review(
    id,
    () => _repository.reviewCash(id, approve: approve, note: note),
  );

  Future<AdminFailure?> reviewCorrection(
    String id, {
    required bool approve,
    String? note,
  }) => _review(
    id,
    () => _repository.reviewCorrection(id, approve: approve, note: note),
  );

  Future<AdminFailure?> _review(String id, Future<void> Function() send) async {
    final current = state;
    if (current is! AssignedReviewsLoaded || current.reviewing.contains(id)) {
      return AdminFailure.busy;
    }
    emit(_with(current, reviewing: {...current.reviewing, id}));

    AdminFailure? failure;
    try {
      await send();
    } catch (error) {
      failure = error is AdminFailure ? error : AdminFailure.unknown;
    }
    if (isClosed) return failure;

    final latest = state;
    if (latest is AssignedReviewsLoaded) {
      emit(
        AssignedReviewsLoaded(
          cash: [
            for (final r in latest.cash)
              if (failure != null || r.id != id) r,
          ],
          corrections: [
            for (final r in latest.corrections)
              if (failure != null || r.id != id) r,
          ],
          reviewing: {...latest.reviewing}..remove(id),
        ),
      );
    }
    // Decided elsewhere, unassigned, the permission was removed, or the
    // answer was lost: show what the database holds now.
    if (failure != null &&
        (failure.needsReload || failure == AdminFailure.notAllowed)) {
      await load();
    }
    return failure;
  }

  static AssignedReviewsLoaded _with(
    AssignedReviewsLoaded state, {
    required Set<String> reviewing,
  }) => AssignedReviewsLoaded(
    cash: state.cash,
    corrections: state.corrections,
    reviewing: reviewing,
  );
}
