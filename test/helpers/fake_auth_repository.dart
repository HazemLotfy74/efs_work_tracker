import 'dart:async';

import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/auth/domain/repositories/auth_repository.dart';
import 'package:efs_work_tracker/core/errors/failure.dart';

UserEntity testUser({bool mustChangePassword = false}) => UserEntity(
  uID: 'user-1',
  email: 'employee@example.com',
  fullName: 'Test Employee',
  username: 'test.employee',
  employeeCode: 'EMP-1',
  role: UserRole.employee,
  isActive: true,
  mustChangePassword: mustChangePassword,
);

/// In-memory [AuthRepository] for tests. Set [signedInUser] for a saved
/// session and [failure] to make the next call fail.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.signedInUser});

  UserEntity? signedInUser;
  AuthFailure? failure;
  final _signedOut = StreamController<void>.broadcast();

  /// Simulates the session ending on its own.
  void endSession() => _signedOut.add(null);

  @override
  Future<UserEntity?> getSignedInUser() async => signedInUser;

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    if (failure case final failure?) throw failure;
    return signedInUser = testUser(mustChangePassword: true);
  }

  @override
  Future<UserEntity> changePassword({required String newPassword}) async {
    if (failure case final failure?) throw failure;
    return signedInUser = testUser();
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    if (failure case final failure?) throw failure;
  }

  @override
  Future<void> signOut() async => signedInUser = null;

  @override
  Stream<void> get signedOut => _signedOut.stream;

  final _recovery = StreamController<void>.broadcast();

  /// Simulates opening a password-reset link: signed in by the link.
  void openResetLink(UserEntity user) {
    signedInUser = user;
    _recovery.add(null);
  }

  @override
  Stream<void> get passwordRecovery => _recovery.stream;
}
