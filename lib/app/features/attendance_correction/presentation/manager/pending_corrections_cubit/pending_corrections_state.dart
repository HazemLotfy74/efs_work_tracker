part of 'pending_corrections_cubit.dart';

sealed class PendingCorrectionsState {
  const PendingCorrectionsState();
}

final class PendingCorrectionsLoading extends PendingCorrectionsState {
  const PendingCorrectionsLoading();
}

final class PendingCorrectionsLoaded extends PendingCorrectionsState {
  const PendingCorrectionsLoaded(this.requests, {this.reviewing = const {}});

  /// Oldest first.
  final List<CorrectionRequestEntity> requests;

  /// Ids of the requests whose review is being sent.
  final Set<String> reviewing;

  PendingCorrectionsLoaded copyWith({
    List<CorrectionRequestEntity>? requests,
    Set<String>? reviewing,
  }) => PendingCorrectionsLoaded(
    requests ?? this.requests,
    reviewing: reviewing ?? this.reviewing,
  );
}

final class PendingCorrectionsError extends PendingCorrectionsState {
  const PendingCorrectionsError();
}
