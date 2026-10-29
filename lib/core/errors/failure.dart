abstract class Failure implements Exception {
  final String message;

  Failure({required this.message});

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  ServerFailure({required super.message});
}

/// Why sign-in, loading the account or changing the password failed.
/// The UI turns each reason into a translated message.
enum AuthFailureReason {
  invalidCredentials,

  /// No profile, deactivated, or rejected by the login hook.
  accountUnavailable,
  emailNotConfirmed,
  tooManyRequests,

  /// Rejected by the server's password rules.
  weakPassword,
  samePassword,

  /// The session is too old for a password change; sign in again.
  reauthenticationNeeded,

  /// Auth may have saved the new password, but the account was not
  /// unlocked. Sign in with the new password and change it once more.
  passwordCompletionPending,
  sessionExpired,
  network,
  unknown,
}

class AuthFailure extends Failure {
  AuthFailure(this.reason, {String? message})
    : super(message: message ?? reason.name);

  final AuthFailureReason reason;

  /// [errorCode] is a Supabase Auth `error_code`, or the `error` field the
  /// `employee-accounts` Edge Function returns.
  factory AuthFailure.fromSupabaseError(String? errorCode, {String? message}) {
    final reason = switch (errorCode) {
      'invalid_credentials' => AuthFailureReason.invalidCredentials,
      'email_not_confirmed' => AuthFailureReason.emailNotConfirmed,
      'user_banned' || 'forbidden' => AuthFailureReason.accountUnavailable,
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' => AuthFailureReason.tooManyRequests,
      'weak_password' || 'invalid_input' => AuthFailureReason.weakPassword,
      'same_password' => AuthFailureReason.samePassword,
      'reauthentication_needed' ||
      'reauthentication_not_valid' => AuthFailureReason.reauthenticationNeeded,
      'password_completion_pending' =>
        AuthFailureReason.passwordCompletionPending,
      'unauthorized' ||
      'session_not_found' ||
      'refresh_token_not_found' => AuthFailureReason.sessionExpired,
      _ => AuthFailureReason.unknown,
    };
    return AuthFailure(reason, message: message ?? errorCode);
  }
}

class CacheFailure extends Failure {
  CacheFailure({required super.message});
}

class OfflineFailure extends Failure {
  OfflineFailure({required super.message});
}

class UnknownFailure extends Failure {
  UnknownFailure({required super.message});
}

class NoInternetFailure extends Failure {
  NoInternetFailure({required super.message});
}
