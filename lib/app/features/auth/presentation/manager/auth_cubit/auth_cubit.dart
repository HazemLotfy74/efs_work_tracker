import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

/// Who is signed in, for the whole app.
///
/// Provided once in main.dart. The router listens to it and sends the user
/// to sign-in, the password change or home.
class AuthCubit extends Cubit<AuthSessionState> {
  AuthCubit(this._repository) : super(const AuthChecking());

  final AuthRepository _repository;
  StreamSubscription<void>? _signedOutSubscription;
  StreamSubscription<void>? _recoverySubscription;

  /// Restores the saved session. Call once at startup.
  Future<void> start() async {
    _signedOutSubscription ??= _repository.signedOut.listen((_) {
      if (!isClosed && state is! AuthSignedOut) emit(const AuthSignedOut());
    });
    _recoverySubscription ??= _repository.passwordRecovery.listen(
      (_) => _recovered(),
    );
    try {
      final user = await _repository.getSignedInUser();
      if (!isClosed) emit(_stateFor(user));
    } catch (_) {
      // Offline at startup: the saved session is kept for the next launch.
      if (!isClosed) emit(const AuthSignedOut());
    }
  }

  /// Throws an `AuthFailure`, so the form can show what went wrong.
  Future<void> signIn({required String email, required String password}) async {
    final user = await _repository.signIn(email: email, password: password);
    if (!isClosed) emit(_stateFor(user));
  }

  /// Throws an `AuthFailure`, so the form can show what went wrong.
  Future<void> changePassword(String newPassword) async {
    final user = await _repository.changePassword(newPassword: newPassword);
    if (!isClosed) emit(_stateFor(user));
  }

  /// Throws an `AuthFailure`, so the form can show what went wrong.
  Future<void> sendPasswordReset(String email) {
    return _repository.sendPasswordReset(email: email);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    if (!isClosed) emit(const AuthSignedOut());
  }

  /// A reset link signed the user in: always ask for a new password, even
  /// if the login hook didn't set `must_change_password`.
  Future<void> _recovered() async {
    try {
      final user = await _repository.getSignedInUser();
      if (isClosed) return;
      emit(
        user == null ? const AuthSignedOut() : AuthPasswordChangeRequired(user),
      );
    } catch (_) {
      if (!isClosed) emit(const AuthSignedOut());
    }
  }

  static AuthSessionState _stateFor(UserEntity? user) {
    if (user == null) return const AuthSignedOut();
    if (user.mustChangePassword) return AuthPasswordChangeRequired(user);
    return AuthSignedIn(user);
  }

  @override
  Future<void> close() async {
    await _signedOutSubscription?.cancel();
    await _recoverySubscription?.cancel();
    return super.close();
  }
}
