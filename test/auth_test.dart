import 'package:efs_work_tracker/app/features/auth/data/models/user_model.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/core/errors/failure.dart';
import 'package:efs_work_tracker/core/functions/form_validator_functions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  group('UserModel.fromAccountStatus', () {
    test('reads every field returned by get_account_status', () {
      final user = UserModel.fromAccountStatus({
        'id': 'abc',
        'full_name': 'Mona Ali Hassan',
        'username': 'mona.ali',
        'employee_code': 'EMP-7',
        'role': 'admin',
        'is_active': true,
        'must_change_password': false,
      }, email: 'mona@example.com');

      expect(user.uID, 'abc');
      expect(user.email, 'mona@example.com');
      expect(user.role, UserRole.admin);
      expect(user.isActive, isTrue);
      expect(user.mustChangePassword, isFalse);
      expect(user.initials, 'MA');
    });

    test('treats missing values as the safer choice', () {
      final user = UserModel.fromAccountStatus({'id': 'abc'}, email: '');

      expect(user.role, UserRole.employee);
      expect(user.isActive, isFalse);
      expect(user.mustChangePassword, isTrue);
    });
  });

  group('AuthCubit', () {
    test('no saved session → signed out', () async {
      final cubit = AuthCubit(FakeAuthRepository());
      await cubit.start();
      expect(cubit.state, isA<AuthSignedOut>());
    });

    test('saved session with a ready account → signed in', () async {
      final cubit = AuthCubit(FakeAuthRepository(signedInUser: testUser()));
      await cubit.start();
      expect(cubit.state, isA<AuthSignedIn>());
    });

    test('new account must change its password first', () async {
      final cubit = AuthCubit(FakeAuthRepository());
      await cubit.start();

      await cubit.signIn(email: 'a@b.co', password: 'secret');
      expect(cubit.state, isA<AuthPasswordChangeRequired>());

      await cubit.changePassword('a-long-new-password');
      expect(cubit.state, isA<AuthSignedIn>());
    });

    test('a failed sign-in throws and stays signed out', () async {
      final repository = FakeAuthRepository()
        ..failure = AuthFailure(AuthFailureReason.invalidCredentials);
      final cubit = AuthCubit(repository);
      await cubit.start();

      await expectLater(
        cubit.signIn(email: 'a@b.co', password: 'wrong'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.reason,
            'reason',
            AuthFailureReason.invalidCredentials,
          ),
        ),
      );
      expect(cubit.state, isA<AuthSignedOut>());
    });

    test('a session that ends on its own signs the user out', () async {
      final repository = FakeAuthRepository(signedInUser: testUser());
      final cubit = AuthCubit(repository);
      await cubit.start();

      repository.endSession();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<AuthSignedOut>());
      await cubit.close();
    });

    test('a password-reset link leads to the password change', () async {
      final repository = FakeAuthRepository();
      final cubit = AuthCubit(repository);
      await cubit.start();
      expect(cubit.state, isA<AuthSignedOut>());

      // Even when the account itself isn't flagged to change its password.
      repository.openResetLink(testUser());
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<AuthPasswordChangeRequired>());
      await cubit.close();
    });
  });

  group('AuthFailure.fromSupabaseError', () {
    test('maps Auth and Edge Function codes', () {
      AuthFailureReason reasonOf(String code) =>
          AuthFailure.fromSupabaseError(code).reason;

      expect(
        reasonOf('invalid_credentials'),
        AuthFailureReason.invalidCredentials,
      );
      expect(reasonOf('forbidden'), AuthFailureReason.accountUnavailable);
      expect(reasonOf('same_password'), AuthFailureReason.samePassword);
      expect(
        reasonOf('password_completion_pending'),
        AuthFailureReason.passwordCompletionPending,
      );
      expect(reasonOf('something_new'), AuthFailureReason.unknown);
    });
  });

  group('newPasswordValidator', () {
    test('matches the Edge Function rules', () {
      expect(newPasswordValidator('short'), isNotNull);
      expect(newPasswordValidator('twelve chars'), isNull);
      expect(newPasswordValidator('a' * 73), isNotNull);
    });
  });
}
