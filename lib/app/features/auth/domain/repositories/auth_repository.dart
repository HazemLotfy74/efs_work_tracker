import '../../../../../core/errors/failure.dart';
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

  /// The login email an admin asked this employee to change to, while the
  /// request is still open; `null` when there is none (or for admins).
  Future<String?> getPendingLoginEmail();

  /// Starts Supabase Auth's own email change to [email]: it emails a
  /// confirmation link, and the change happens when the link is opened.
  /// The database refuses any address an admin did not request.
  Future<void> confirmLoginEmail(String email);

  /// Fires when the session ends on its own, e.g. a refresh is refused
  /// because the account was deactivated.
  Stream<void> get signedOut;

  /// Fires when a password-reset link signed the user in. They must choose
  /// a new password before anything else.
  Stream<void> get passwordRecovery;

  /// Fires when a password-reset link could not sign the user in: it
  /// expired, was already used, or was opened on another phone.
  Stream<AuthFailure> get recoveryLinkFailed;
}
