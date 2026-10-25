import 'package:efs_work_tracker/app/features/attendance_session/data/repositories/in_memory_attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/repositories/attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The app-wide providers from main.dart, for widget tests.
Widget withAppProviders(Widget child, {AttendanceRepository? repository}) {
  final repo = repository ?? InMemoryAttendanceRepository();
  return RepositoryProvider<AttendanceRepository>.value(
    value: repo,
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ClockCubit()),
        BlocProvider(create: (_) => AttendanceSessionCubit(repo)..load()),
      ],
      child: child,
    ),
  );
}
