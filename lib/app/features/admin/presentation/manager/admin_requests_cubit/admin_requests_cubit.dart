import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/admin_errors.dart';
import '../../../domain/entities/admin_request_entity.dart';
import '../../../domain/repositories/admin_repository.dart';

part 'admin_requests_state.dart';

/// Pending cash requests to approve or reject.
class AdminRequestsCubit extends Cubit<AdminRequestsState> {
  AdminRequestsCubit(this._repository) : super(const AdminRequestsLoading());

  final AdminRepository _repository;

  /// Only the newest load may emit.
  int _loadId = 0;

  Future<void> load() async {
    final loadId = ++_loadId;
    if (state is! AdminRequestsLoaded) emit(const AdminRequestsLoading());
    try {
      final requests = await _repository.getPendingRequests();
      if (isClosed || loadId != _loadId) return;
      final reviewing = switch (state) {
        AdminRequestsLoaded(:final reviewing) => reviewing,
        _ => const <String>{},
      };
      emit(AdminRequestsLoaded(requests, reviewing: reviewing));
    } catch (_) {
      if (isClosed || loadId != _loadId) return;
      if (state is! AdminRequestsLoaded) emit(const AdminRequestsError());
    }
  }

  /// Returns why it failed, or `null`. A reviewed request leaves the list.
  Future<AdminFailure?> review(
    AdminRequestEntity request, {
    required bool approve,
    String? note,
  }) async {
    final current = state;
    if (current is! AdminRequestsLoaded ||
        current.reviewing.contains(request.id)) {
      return AdminFailure.busy;
    }
    emit(current.copyWith(reviewing: {...current.reviewing, request.id}));

    AdminFailure? failure;
    try {
      await _repository.review(request, approve: approve, note: note);
    } catch (error) {
      failure = error is AdminFailure ? error : AdminFailure.unknown;
    }
    if (isClosed) return failure;

    final latest = state;
    if (latest is AdminRequestsLoaded) {
      emit(
        latest.copyWith(
          requests: failure == null
              ? [
                  for (final r in latest.requests)
                    if (r.id != request.id) r,
                ]
              : latest.requests,
          reviewing: {...latest.reviewing}..remove(request.id),
        ),
      );
    }
    if (failure != null && failure.needsReload) await load();
    return failure;
  }
}
