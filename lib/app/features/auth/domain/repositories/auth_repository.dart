import '../entities/user_entity.dart';

/// Signing in and out, and loading the signed-in account.
///
/// Every method throws an `AuthFailure` (core/errors/failure.dart) on error.
abstract interface class AuthRepository {
  /// The account of the saved session, or `null` when nobody is signed in.
  Future<UserEntity?> getSignedInUser();

  Future<UserEntity> signIn({required String email, required String password});

  /// Sets a new password and returns the account, now unlocked.
  Future<UserEntity> changePassword({required String newPassword});

  Future<void> sendPasswordReset({required String email});

  Future<void> signOut();

  /// Fires when the session ends on its own, e.g. a refresh is refused
  /// because the account was deactivated.
  Stream<void> get signedOut;

  /// Fires when a password-reset link signed the user in. They must choose
  /// a new password before anything else.
  Stream<void> get passwordRecovery;
}
