import 'package:efs_work_tracker/app/features/attendance_correction/domain/repositories/correction_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/repositories/in_memory_attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/repositories/attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/admin/domain/repositories/admin_repository.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/core/manager/locale_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'fake_admin_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_correction_repository.dart';

/// The app-wide providers from main.dart, for widget tests.
Widget withAppProviders(
  Widget child, {
  AttendanceRepository? repository,
  CorrectionRepository? corrections,
  AdminRepository? admin,
}) {
  final repo = repository ?? InMemoryAttendanceRepository();
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AttendanceRepository>.value(value: repo),
      RepositoryProvider<CorrectionRepository>.value(
        value: corrections ?? FakeCorrectionRepository(),
      ),
      RepositoryProvider<AdminRepository>.value(
        value: admin ?? FakeAdminRepository(),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              AuthCubit(FakeAuthRepository(signedInUser: testUser()))..start(),
        ),
        BlocProvider(create: (_) => ClockCubit()),
        BlocProvider(create: (_) => AttendanceSessionCubit(repo)..load()),
        BlocProvider(create: (_) => LocaleCubit(MemoryLocaleStore())),
      ],
      child: child,
    ),
  );
}
