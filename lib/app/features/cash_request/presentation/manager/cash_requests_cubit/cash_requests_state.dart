part of 'cash_requests_cubit.dart';

sealed class CashRequestsState {
  const CashRequestsState({this.filter});

  /// Status shown in the list; `null` shows every request.
  final RequestStatus? filter;
}

final class CashRequestsLoading extends CashRequestsState {
  const CashRequestsLoading({super.filter});
}

final class CashRequestsLoaded extends CashRequestsState {
  const CashRequestsLoaded(this.requests, {super.filter});

  /// Newest first.
  final List<ExpenseAdvanceRequestEntity> requests;

  /// [requests] with the [filter] status.
  List<ExpenseAdvanceRequestEntity> get visible => filter == null
      ? requests
      : requests.where((request) => request.status == filter).toList();

  /// Total amount still waiting for an administrator, per currency.
  Map<String, num> get pendingTotals {
    final totals = <String, num>{};
    for (final request in requests) {
      if (request.status != RequestStatus.pending) continue;
      totals[request.currency] =
          (totals[request.currency] ?? 0) + request.amount;
    }
    return totals;
  }
}

final class CashRequestsError extends CashRequestsState {
  const CashRequestsError(this.failure, {super.filter});

  final RequestFailure failure;
}
