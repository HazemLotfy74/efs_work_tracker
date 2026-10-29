import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/features/admin/domain/repositories/admin_repository.dart';
import 'app/features/attendance_correction/domain/repositories/correction_repository.dart';
import 'app/features/attendance_session/domain/repositories/attendance_repository.dart';
import 'app/features/attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'app/features/auth/domain/repositories/auth_repository.dart';
import 'app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'app/features/cash_request/domain/repositories/expense_advance_repository.dart';
import 'core/constants/constants.dart';
import 'core/manager/clock_cubit.dart';
import 'core/manager/locale_cubit.dart';
import 'core/router/app_router.dart';
import 'core/services/getit_services.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    publishableKey: Constants.supabaseKey,
  );
  setup();
  // Created here, not in build, so the router and its guard exist only once.
  final authCubit = AuthCubit(getIt<AuthRepository>());
  final attendanceCubit = AttendanceSessionCubit(getIt<AttendanceRepository>());
  // Attendance follows the signed-in account: loaded once it can record
  // attendance, cleared on sign-out. Subscribed before start() so the
  // first state is not missed.
  authCubit.stream
      .map((state) => state is AuthSignedIn ? state.user.uID : null)
      .listen(attendanceCubit.userChanged);
  authCubit.start();
  // Back in the app: the day may have changed (check-out on another phone,
  // automatic close at the shift end).
  AppLifecycleListener(
    onResume: () {
      if (authCubit.state is AuthSignedIn) attendanceCubit.load();
    },
  );
  runApp(
    WorkTrackApp(
      authCubit: authCubit,
      attendanceCubit: attendanceCubit,
      router: AppRouter.create(authCubit),
    ),
  );
}

class WorkTrackApp extends StatelessWidget {
  const WorkTrackApp({
    super.key,
    required this.authCubit,
    required this.attendanceCubit,
    required this.router,
  });

  final AuthCubit authCubit;
  final AttendanceSessionCubit attendanceCubit;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    // Everything here sits above the router, so every screen shares it.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AttendanceRepository>.value(
          value: getIt<AttendanceRepository>(),
        ),
        RepositoryProvider<CorrectionRepository>.value(
          value: getIt<CorrectionRepository>(),
        ),
        RepositoryProvider<ExpenseAdvanceRepository>.value(
          value: getIt<ExpenseAdvanceRepository>(),
        ),
        RepositoryProvider<AdminRepository>.value(
          value: getIt<AdminRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authCubit),
          // lazy: false starts them with the app, not on first use.
          BlocProvider(create: (_) => ClockCubit(), lazy: false),
          BlocProvider.value(value: attendanceCubit),
          BlocProvider(
            create: (_) => LocaleCubit(SharedPreferencesLocaleStore())..load(),
            lazy: false,
          ),
        ],
        // Changing the language rebuilds the app in place: the router, the
        // session and every cubit above stay as they are.
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) => MaterialApp.router(
            title: 'Efs WorkTrack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
          ),
        ),
      ),
    );
  }
}
