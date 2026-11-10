import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/failure.dart';
import '../../../../../core/services/database_services.dart';
import '../../../../../core/services/supabase_auth_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required this._authService,
    required this._databaseServices,
  });

  final SupabaseAuthService _authService;
  final DatabaseServices _databaseServices;

  @override
  Future<UserEntity?> getSignedInUser() async {
    if (_authService.currentUser == null) return null;
    try {
      return await _loadAccount();
    } on AuthFailure catch (failure) {
      if (failure.reason == AuthFailureReason.network) rethrow;
      await _authService.signOut();
      return null;
    }
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    await _authService.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    try {
      return await _loadAccount();
    } on AuthFailure {
      // Don't keep a session for an account the app can't load.
      await _authService.signOut();
      rethrow;
    }
  }

  @override
  Future<UserEntity> changePassword({required String newPassword}) async {
    await _authService.changePassword(newPassword: newPassword);
    return _loadAccount();
  }

  @override
  Future<void> sendPasswordReset({required String email}) {
    return _authService.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
    );
  }

  @override
  Future<void> signOut() => _authService.signOut();

  @override
  Stream<void> get signedOut => _events
      .where((state) => state.event == AuthChangeEvent.signedOut)
      .map((_) {});

  @override
  Stream<void> get passwordRecovery => _events
      .where((state) => state.event == AuthChangeEvent.passwordRecovery)
      .map((_) {});

  /// Auth state changes without their errors. supabase_flutter reports a
  /// bad deep link (e.g. an expired reset link) as a stream error; it is
  /// handled by [recoveryLinkFailed], never left uncaught.
  Stream<AuthState> get _events =>
      _authService.onAuthStateChange.handleError((Object _) {});

  @override
  Stream<AuthFailure> get recoveryLinkFailed =>
      _authService.onAuthStateChange.transform(
        StreamTransformer<AuthState, AuthFailure>.fromHandlers(
          handleData: (_, _) {},
          handleError: (error, _, sink) {
            // Only the error code is kept: the URL can hold secrets.
            if (error is AuthException) {
              sink.add(
                AuthFailure(
                  AuthFailureReason.recoveryLinkInvalid,
                  message: error.code ?? error.statusCode,
                ),
              );
            }
          },
        ),
      );

  /// Uses `get_account_status`: the only way to read your own profile while
  /// `must_change_password` is true (RLS hides the row until then).
  Future<UserEntity> _loadAccount() async {
    final user = _authService.currentUser;
    if (user == null) throw AuthFailure(AuthFailureReason.sessionExpired);

    final Object? data;
    try {
      data = await _databaseServices.rpc(function: 'get_account_status');
    } on PostgrestException catch (e) {
      // 42501: the account has no profile.
      throw e.code == '42501'
          ? AuthFailure(AuthFailureReason.accountUnavailable)
          : AuthFailure(AuthFailureReason.unknown, message: e.code);
    } on Exception {
      throw AuthFailure(AuthFailureReason.network);
    }
    if (data is! Map) throw AuthFailure(AuthFailureReason.unknown);

    final account = UserModel.fromAccountStatus(
      Map<String, dynamic>.from(data),
      email: user.email ?? '',
    );
    if (!account.isActive) {
      throw AuthFailure(AuthFailureReason.accountUnavailable);
    }
    return account;
  }
}
