part of 'admin_requests_cubit.dart';

sealed class AdminRequestsState {
  const AdminRequestsState();
}

final class AdminRequestsLoading extends AdminRequestsState {
  const AdminRequestsLoading();
}

final class AdminRequestsLoaded extends AdminRequestsState {
  const AdminRequestsLoaded(this.requests, {this.reviewing = const {}});

  /// Oldest first.
  final List<AdminRequestEntity> requests;

  /// Ids whose review is being sent.
  final Set<String> reviewing;

  AdminRequestsLoaded copyWith({
    List<AdminRequestEntity>? requests,
    Set<String>? reviewing,
  }) => AdminRequestsLoaded(
    requests ?? this.requests,
    reviewing: reviewing ?? this.reviewing,
  );
}

final class AdminRequestsError extends AdminRequestsState {
  const AdminRequestsError();
}
