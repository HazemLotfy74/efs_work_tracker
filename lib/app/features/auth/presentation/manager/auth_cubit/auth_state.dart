part of 'auth_cubit.dart';

sealed class AuthSessionState {
  const AuthSessionState();
}

/// Restoring the saved session at startup.
final class AuthChecking extends AuthSessionState {
  const AuthChecking();
}

final class AuthSignedOut extends AuthSessionState {
  const AuthSignedOut();
}

/// Signed in, but the database blocks every feature until the password
/// is changed.
final class AuthPasswordChangeRequired extends AuthSessionState {
  const AuthPasswordChangeRequired(this.user);
  final UserEntity user;
}

final class AuthSignedIn extends AuthSessionState {
  const AuthSignedIn(this.user);
  final UserEntity user;
}
