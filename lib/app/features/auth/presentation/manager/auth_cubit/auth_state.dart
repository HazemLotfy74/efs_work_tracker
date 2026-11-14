part of 'auth_cubit.dart';

sealed class AuthSessionState {
  const AuthSessionState();
}

/// Restoring the saved session at startup.
final class AuthChecking extends AuthSessionState {
  const AuthChecking();
}

final class AuthSignedOut extends AuthSessionState {
  const AuthSignedOut({this.linkFailure});

  /// Why the user is back on the sign-in screen without having asked: a
  /// password-reset link that couldn't be used, or the account was signed
  /// in on another phone. Shown once on the sign-in screen.
  final AuthFailureReason? linkFailure;
}

/// Signed in, but the database blocks every feature until the password
/// is changed.
final class AuthPasswordChangeRequired extends AuthSessionState {
  const AuthPasswordChangeRequired(this.user, {this.fromResetLink = false});
  final UserEntity user;

  /// Opened from a password-reset email: the screen says "Reset password".
  final bool fromResetLink;
}

final class AuthSignedIn extends AuthSessionState {
  const AuthSignedIn(this.user);
  final UserEntity user;
}
