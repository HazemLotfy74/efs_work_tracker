part of 'audit_history_cubit.dart';

sealed class AuditHistoryState {
  const AuditHistoryState();
}

final class AuditHistoryLoading extends AuditHistoryState {
  const AuditHistoryLoading();
}

final class AuditHistoryError extends AuditHistoryState {
  const AuditHistoryError();
}

final class AuditHistoryLoaded extends AuditHistoryState {
  const AuditHistoryLoaded(this.entries, this.names);

  /// Newest first.
  final List<AuditEntryEntity> entries;

  /// Account id → full name.
  final Map<String, String> names;
}
