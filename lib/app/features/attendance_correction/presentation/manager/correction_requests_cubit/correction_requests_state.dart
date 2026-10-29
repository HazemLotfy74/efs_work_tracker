part of 'correction_requests_cubit.dart';

sealed class CorrectionRequestsState {
  const CorrectionRequestsState();
}

final class CorrectionRequestsLoading extends CorrectionRequestsState {
  const CorrectionRequestsLoading();
}

final class CorrectionRequestsLoaded extends CorrectionRequestsState {
  const CorrectionRequestsLoaded(this.requests);

  /// Newest first; empty before the first request.
  final List<CorrectionRequestEntity> requests;

  CorrectionRequestEntity? get latest => requests.firstOrNull;

  /// The database allows one pending request per day.
  bool get hasPending => requests.any((request) => request.isPending);
}

final class CorrectionRequestsError extends CorrectionRequestsState {
  const CorrectionRequestsError();
}
