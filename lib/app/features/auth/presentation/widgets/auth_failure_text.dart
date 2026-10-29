import '../../../../../core/errors/failure.dart';
import '../../../../../l10n/app_localizations.dart';

/// Message shown to the user for each [AuthFailureReason].
extension AuthFailureText on AuthFailureReason {
  String message(AppLocalizations l10n) {
    return switch (this) {
      AuthFailureReason.invalidCredentials => l10n.authInvalidCredentials,
      AuthFailureReason.accountUnavailable => l10n.authAccountUnavailable,
      AuthFailureReason.emailNotConfirmed => l10n.authEmailNotConfirmed,
      AuthFailureReason.tooManyRequests => l10n.authTooManyRequests,
      AuthFailureReason.weakPassword => l10n.authWeakPassword,
      AuthFailureReason.samePassword => l10n.authSamePassword,
      AuthFailureReason.reauthenticationNeeded =>
        l10n.authReauthenticationNeeded,
      AuthFailureReason.passwordCompletionPending =>
        l10n.authPasswordCompletionPending,
      AuthFailureReason.sessionExpired => l10n.authSessionExpired,
      AuthFailureReason.network => l10n.authNetworkError,
      AuthFailureReason.unknown => l10n.authUnknownError,
    };
  }
}

/// The message for any error thrown by the auth cubit.
String authErrorMessage(Object error, AppLocalizations l10n) {
  final reason = error is AuthFailure
      ? error.reason
      : AuthFailureReason.unknown;
  return reason.message(l10n);
}
