import 'dart:developer';

import 'package:efs_work_tracker/core/errors/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/constants.dart';

/// Supabase Auth calls. Every method throws an [AuthFailure] on error.
class SupabaseAuthService {
  GoTrueClient get _auth => Constants.supabase.auth;

  User? get currentUser => _auth.currentUser;

  /// Fires on sign-in, sign-out, token refresh and failed refreshes.
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user!;
    } on AuthException catch (e) {
      log('Sign-in failed: status ${e.statusCode}, code ${e.code}');
      throw _toFailure(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      // The local session is cleared even when the server call fails.
      log('Sign-out failed: status ${e.statusCode}, code ${e.code}');
    }
  }

  /// Supabase answers the same way whether or not the email exists.
  ///
  /// The link opens this app ([Constants.passwordResetRedirect]); without
  /// `redirectTo` it opened the project's Site URL in a browser and the
  /// app never received the recovery session. With the PKCE flow the link
  /// must be opened on the phone that asked for it.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.resetPasswordForEmail(
        email,
        redirectTo: Constants.passwordResetRedirect,
      );
    } on AuthException catch (e) {
      log('Password reset failed: status ${e.statusCode}, code ${e.code}');
      throw _toFailure(e);
    }
  }

  /// Changes the password through the `employee-accounts` Edge Function,
  /// which also clears `must_change_password`. Calling `auth.updateUser`
  /// directly would leave the account locked.
  Future<void> changePassword({required String newPassword}) async {
    final session = _auth.currentSession;
    if (session == null) {
      throw AuthFailure(AuthFailureReason.sessionExpired);
    }
    try {
      await Constants.supabase.functions.invoke(
        Constants.accountsFunction,
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'action': 'change_password', 'password': newPassword},
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final code = details is Map ? details['error'] as String? : null;
      log('Password change failed: status ${e.status}, code $code');
      if (e.status == 429) {
        throw AuthFailure(AuthFailureReason.tooManyRequests);
      }
      // No answer: offline, or in a web browser a refused CORS preflight
      // (the function only accepts its ALLOWED_WEB_ORIGIN).
      if (e.status == 0) throw AuthFailure(AuthFailureReason.network);
      throw AuthFailure.fromSupabaseError(code);
    } catch (e) {
      log('Password change failed: $e');
      throw AuthFailure(AuthFailureReason.network);
    }
  }

  AuthFailure _toFailure(AuthException e) {
    if (e is AuthRetryableFetchException) {
      return AuthFailure(AuthFailureReason.network);
    }
    // The access token hook rejects missing or inactive profiles with 403.
    if (e.statusCode == '403' && e.code == null) {
      return AuthFailure(AuthFailureReason.accountUnavailable);
    }
    if (e.statusCode == '429') {
      return AuthFailure(AuthFailureReason.tooManyRequests);
    }
    return AuthFailure.fromSupabaseError(e.code);
  }
}
