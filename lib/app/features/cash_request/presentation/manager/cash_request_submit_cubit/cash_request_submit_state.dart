part of 'cash_request_submit_cubit.dart';

sealed class CashRequestSubmitState {
  const CashRequestSubmitState();
}

final class CashRequestSubmitIdle extends CashRequestSubmitState {
  const CashRequestSubmitIdle();
}

final class CashRequestSubmitting extends CashRequestSubmitState {
  const CashRequestSubmitting();
}

final class CashRequestSubmitted extends CashRequestSubmitState {
  const CashRequestSubmitted(this.request);

  /// Saved as pending, waiting for an administrator.
  final ExpenseAdvanceRequestEntity request;
}

final class CashRequestSubmitFailed extends CashRequestSubmitState {
  const CashRequestSubmitFailed(this.failure);

  final RequestFailure failure;
}
