import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/login_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/widgets/auth_failure_text.dart';
import 'package:efs_work_tracker/core/errors/failure.dart';
import 'package:efs_work_tracker/core/manager/locale_cubit.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_auth_repository.dart';

/// What `SupabaseAuthRepository.getSignedInUser` does when the server says
/// the session was replaced: the local session is dropped and the reason is
/// rethrown. A network or unknown error is rethrown with the session kept.
class _Sessions extends FakeAuthRepository {
  _Sessions() : super(signedInUser: testUser());

  AuthFailureReason? serverSays;
  int checks = 0;

  @override
  Future<UserEntity?> getSignedInUser() async {
    checks++;
    final reason = serverSays;
    if (reason == null) return signedInUser;
    if (reason != AuthFailureReason.network &&
        reason != AuthFailureReason.unknown) {
      signedInUser = null;
    }
    if (reason == AuthFailureReason.sessionExpired) return null;
    throw AuthFailure(reason);
  }
}

const _arabic =
    'تم تسجيل الدخول إلى حسابك من جهاز آخر. يرجى تسجيل الدخول مرة أخرى للمتابعة.';

void main() {
  test('the message is the one asked for, in Arabic and English', () {
    expect(
      AuthFailureReason.sessionReplaced.message(
        lookupAppLocalizations(const Locale('ar')),
      ),
      _arabic,
    );
    expect(
      AuthFailureReason.sessionReplaced.message(
        lookupAppLocalizations(const Locale('en')),
      ),
      contains('another device'),
    );
  });

  group('AuthCubit.verifySession', () {
    late _Sessions sessions;
    late AuthCubit cubit;

    setUp(() async {
      sessions = _Sessions();
      cubit = AuthCubit(sessions);
      await cubit.start();
      expect(cubit.state, isA<AuthSignedIn>());
    });
    tearDown(() => cubit.close());

    test('still the active session: nothing changes, nothing reloads', () async {
      final before = cubit.state;
      final emitted = <AuthSessionState>[];
      final subscription = cubit.stream.listen(emitted.add);
      await cubit.verifySession();
      await cubit.verifySession();
      await subscription.cancel();
      expect(identical(cubit.state, before), isTrue);
      expect(emitted, isEmpty);
    });

    test('signed in on another phone: signed out here, with the reason', () async {
      sessions.serverSays = AuthFailureReason.sessionReplaced;
      await cubit.verifySession();
      final state = cubit.state;
      expect(state, isA<AuthSignedOut>());
      expect(
        (state as AuthSignedOut).linkFailure,
        AuthFailureReason.sessionReplaced,
      );
      expect(sessions.signedInUser, isNull, reason: 'local session dropped');
    });

    test('session ended some other way: signed out, no misleading reason', () async {
      sessions.serverSays = AuthFailureReason.sessionExpired;
      await cubit.verifySession();
      expect(cubit.state, isA<AuthSignedOut>());
      expect((cubit.state as AuthSignedOut).linkFailure, isNull);
    });

    test('an account an admin deactivated is signed out at the next check', () async {
      sessions.serverSays = AuthFailureReason.accountUnavailable;
      await cubit.verifySession();
      expect(cubit.state, isA<AuthSignedOut>());
      expect(sessions.signedInUser, isNull);
    });

    test('offline or a server error is not a verdict: stays signed in', () async {
      for (final reason in [
        AuthFailureReason.network,
        AuthFailureReason.unknown,
      ]) {
        sessions.serverSays = reason;
        await cubit.verifySession();
        expect(cubit.state, isA<AuthSignedIn>(), reason: reason.name);
        expect(sessions.signedInUser, isNotNull);
      }
    });

    test('two checks at once ask the server once', () async {
      final before = sessions.checks;
      await Future.wait([cubit.verifySession(), cubit.verifySession()]);
      expect(sessions.checks, before + 1);
    });

    test('nobody signed in: no request at all', () async {
      await cubit.signOut();
      final before = sessions.checks;
      await cubit.verifySession();
      expect(sessions.checks, before);
    });

    test('the same account can sign in again afterwards', () async {
      sessions.serverSays = AuthFailureReason.sessionReplaced;
      await cubit.verifySession();
      sessions.serverSays = null;
      await cubit.signIn(email: 'employee@example.com', password: 'x');
      expect(cubit.state, isNot(isA<AuthSignedOut>()));
    });
  });

  test('app restart on the replaced phone lands on sign-in with the reason', () async {
    final sessions = _Sessions()
      ..serverSays = AuthFailureReason.sessionReplaced;
    final cubit = AuthCubit(sessions);
    addTearDown(cubit.close);
    await cubit.start();
    expect(
      (cubit.state as AuthSignedOut).linkFailure,
      AuthFailureReason.sessionReplaced,
    );
  });

  testWidgets('the sign-in screen shows the Arabic message, no raw error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sessions = _Sessions();
    final cubit = AuthCubit(sessions);
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider(create: (_) => LocaleCubit(_NoStore())),
        ],
        child: MaterialApp(
          theme: AppTheme.lightFor(const Locale('ar')),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocBuilder<AuthCubit, AuthSessionState>(
            builder: (context, state) => state is AuthSignedIn
                ? const Scaffold(body: Text('home'))
                : const LoginView(),
          ),
        ),
      ),
    );
    expect(find.text('home'), findsOneWidget);

    sessions.serverSays = AuthFailureReason.sessionReplaced;
    await cubit.verifySession();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('home'), findsNothing);
    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text(_arabic), findsOneWidget);
    expect(find.textContaining('42501'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _NoStore implements LocaleStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String languageCode) async {}
}
