import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/features/admin/domain/repositories/admin_repository.dart';
import 'app/features/assigned_reviews/domain/repositories/assigned_review_repository.dart';
import 'app/features/attendance_correction/domain/repositories/correction_repository.dart';
import 'app/features/attendance_session/domain/repositories/attendance_repository.dart';
import 'app/features/attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'app/features/auth/domain/repositories/auth_repository.dart';
import 'app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'app/features/cash_request/domain/repositories/expense_advance_repository.dart';
import 'core/constants/constants.dart';
import 'app/features/history/domain/repositories/history_repository.dart';
import 'app/features/notifications/data/inbox_repository.dart';
import 'app/features/notifications/data/phone_alerts.dart';
import 'app/features/notifications/presentation/inbox_cubit.dart';
import 'core/manager/clock_cubit.dart';
import 'core/manager/locale_cubit.dart';
import 'core/router/app_router.dart';
import 'app/features/hr_reports/domain/repositories/hr_report_repository.dart';
import 'app/features/permissions/domain/repositories/permission_repository.dart';
import 'app/features/permissions/presentation/manager/permissions_cubit.dart';
import 'core/router/app_routes.dart';
import 'core/services/getit_services.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/feedback/app_message_type.dart';
import 'core/widgets/feedback/app_snack_bar.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    publishableKey: Constants.supabaseKey,
  );
  setup();
  // Created here, not in build, so the router and its guard exist only once.
  final phoneAlerts = await PhoneAlerts.initialize(Supabase.instance.client);
  final authCubit = AuthCubit(
    getIt<AuthRepository>(),
    beforeSignOut: phoneAlerts?.beforeSignOut,
  );
  final attendanceCubit = AttendanceSessionCubit(getIt<AttendanceRepository>());
  final inboxCubit = InboxCubit(InboxRepository(Supabase.instance.client));
  // Attendance follows the signed-in account: loaded once it can record
  // attendance, cleared on sign-out. Subscribed before start() so the
  // first state is not missed.
  authCubit.stream
      .map((state) => state is AuthSignedIn ? state.user.uID : null)
      .listen(attendanceCubit.userChanged);
  // Permissions follow the account the same way.
  final permissionsCubit = PermissionsCubit(
    getIt<PermissionRepository>(),
    enabled: Constants.dynamicPermissions,
  );
  authCubit.stream
      .map((state) => state is AuthSignedIn ? state.user : null)
      .distinct((a, b) => a?.uID == b?.uID && a?.role == b?.role)
      .listen(permissionsCubit.userChanged);
  // One router: its guard needs both the session and the permissions.
  final router = AppRouter.create(authCubit, permissionsCubit);
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  var pendingAlertTap = false;
  void openAlertsIfReady() {
    if (!pendingAlertTap || authCubit.state is! AuthSignedIn) return;
    pendingAlertTap = false;
    inboxCubit.refresh();
    router.go(AppRoutes.notifications);
  }

  authCubit.stream.listen((state) {
    final recipient = state is AuthSignedIn ? state.user.uID : null;
    inboxCubit.userChanged(recipient);
    phoneAlerts?.userChanged(recipient);
    openAlertsIfReady();
  });
  authCubit.start();
  // Back in the app: the day may have changed (check-out on another phone,
  // automatic close at the shift end), and so may the permissions.
  AppLifecycleListener(
    onResume: () {
      // First: another phone may have signed in to this account meanwhile.
      authCubit.verifySession();
      if (authCubit.state is AuthSignedIn) {
        attendanceCubit.load();
        permissionsCubit.refresh();
        inboxCubit.refresh();
      }
      phoneAlerts?.refresh();
    },
  );
  // While the app stays open, notice within a minute that the account was
  // signed in elsewhere. This is only for the message and the sign-in
  // screen: the database refuses a replaced session at once, on its own.
  // The same tick picks up permissions an admin granted or removed, so the
  // screens follow without a restart (the database applies them at once).
  Timer.periodic(const Duration(minutes: 1), (_) {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      authCubit.verifySession();
      if (authCubit.state is AuthSignedIn) permissionsCubit.refresh();
    }
  });
  // Notifications arrive live (InboxRepository.watch) and by push. This
  // quiet check covers a dropped live connection or a database where live
  // updates are not switched on: the list and badge are never more than a
  // few seconds behind while the app is open.
  Timer.periodic(const Duration(seconds: 20), (_) {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
        authCubit.state is AuthSignedIn) {
      inboxCubit.refresh(quiet: true);
    }
  });
  final app = BlocProvider.value(
    value: inboxCubit,
    child: WorkTrackApp(
      authCubit: authCubit,
      attendanceCubit: attendanceCubit,
      permissionsCubit: permissionsCubit,
      router: router,
      messengerKey: messengerKey,
    ),
  );
  runApp(
    phoneAlerts == null
        ? app
        : RepositoryProvider.value(value: phoneAlerts, child: app),
  );
  phoneAlerts?.listen(
    onTap: () {
      pendingAlertTap = true;
      openAlertsIfReady();
    },
    // The app is open: refresh the list and badge, and say so in the app.
    onForeground: (title, body) {
      inboxCubit.refresh();
      final messenger = messengerKey.currentState;
      final text = [title, body].whereType<String>().join(' — ');
      if (messenger != null && text.isNotEmpty) {
        showAppSnackBar(messenger, text, type: AppMessageType.info);
      }
    },
  );
}

class WorkTrackApp extends StatelessWidget {
  const WorkTrackApp({
    super.key,
    required this.authCubit,
    required this.attendanceCubit,
    required this.permissionsCubit,
    required this.router,
    this.messengerKey,
  });

  final AuthCubit authCubit;
  final AttendanceSessionCubit attendanceCubit;
  final PermissionsCubit permissionsCubit;
  final GoRouter router;

  /// Lets code outside the widget tree (a push arriving) show a message.
  final GlobalKey<ScaffoldMessengerState>? messengerKey;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HistoryRepository>.value(
          value: getIt<HistoryRepository>(),
        ),
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
        RepositoryProvider<HrReportRepository>.value(
          value: getIt<HrReportRepository>(),
        ),
        RepositoryProvider<AssignedReviewRepository>.value(
          value: getIt<AssignedReviewRepository>(),
        ),
        RepositoryProvider<PermissionRepository>.value(
          value: getIt<PermissionRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authCubit),
          // lazy: false starts them with the app, not on first use.
          BlocProvider(create: (_) => ClockCubit(), lazy: false),
          BlocProvider.value(value: attendanceCubit),
          BlocProvider.value(value: permissionsCubit),
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
            scaffoldMessengerKey: messengerKey,
            theme: AppTheme.lightFor(locale),
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
