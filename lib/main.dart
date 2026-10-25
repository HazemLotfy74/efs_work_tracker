import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/features/attendance_session/data/repositories/in_memory_attendance_repository.dart';
import 'app/features/attendance_session/domain/repositories/attendance_repository.dart';
import 'app/features/attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'core/manager/clock_cubit.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const WorkTrackApp());
}

class WorkTrackApp extends StatelessWidget {
  const WorkTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Everything here sits above the router, so every screen shares it.
    return RepositoryProvider<AttendanceRepository>(
      // Supabase: replace with SupabaseAttendanceRepository(...) here.
      create: (_) => InMemoryAttendanceRepository(),
      child: MultiBlocProvider(
        providers: [
          // lazy: false starts them with the app, not on first use.
          BlocProvider(create: (_) => ClockCubit(), lazy: false),
          BlocProvider(
            create: (context) =>
                AttendanceSessionCubit(context.read<AttendanceRepository>())
                  ..load(),
            lazy: false,
          ),
        ],
        child: MaterialApp.router(
          title: 'Efs WorkTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: AppRouter.router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
        ),
      ),
    );
  }
}
