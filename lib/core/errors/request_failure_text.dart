import '../../l10n/app_localizations.dart';
import 'request_errors.dart';

/// Message shown to the user for each [RequestFailure].
extension RequestFailureText on RequestFailure {
  String message(AppLocalizations l10n) {
    return switch (this) {
      RequestFailure.accountNotReady => l10n.requestAccountNotReady,
      RequestFailure.duplicate => l10n.overtimeDuplicate,
      RequestFailure.invalidHours => l10n.overtimeHoursInvalid,
      RequestFailure.invalidAmount => l10n.cashAmountInvalid,
      RequestFailure.invalidCurrency => l10n.requestInvalidCurrency,
      RequestFailure.invalidReason => l10n.requestReasonInvalid,
      RequestFailure.invalidInput => l10n.requestInvalidInput,
      RequestFailure.busy => l10n.requestBusy,
      RequestFailure.outcomeUnknown => l10n.requestOutcomeUnknown,
      RequestFailure.network => l10n.requestNetworkError,
      RequestFailure.serviceUnavailable => l10n.requestServiceUnavailable,
      RequestFailure.unknown => l10n.requestUnknownError,
    };
  }
}
