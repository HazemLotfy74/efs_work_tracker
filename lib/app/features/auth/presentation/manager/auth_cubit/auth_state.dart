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

  /// Why a password-reset link couldn't sign the user in (expired, used,
  /// or opened on another phone); shown once on the sign-in screen.
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
