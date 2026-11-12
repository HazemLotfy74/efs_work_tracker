import 'package:efs_work_tracker/app/features/admin/domain/repositories/admin_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/domain/repositories/correction_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/repositories/in_memory_attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/repositories/attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/history/domain/repositories/history_repository.dart';
import 'package:efs_work_tracker/app/features/permissions/domain/entities/permission_set.dart';
import 'package:efs_work_tracker/app/features/permissions/domain/repositories/permission_repository.dart';
import 'package:efs_work_tracker/app/features/permissions/presentation/manager/permissions_cubit.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/core/manager/locale_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'attendance_history_adapter.dart';
import 'fake_admin_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_correction_repository.dart';

/// The app-wide providers from main.dart, for widget tests.
///
/// [user] is the signed-in account (an employee by default). [history]
/// defaults to an adapter over [repository], so History reads the same
/// test days as the rest of the app. [permissions] default to the role's,
/// or to every permission when an [admin] repository is given (the test
/// drives admin screens).
Widget withAppProviders(
  Widget child, {
  AttendanceRepository? repository,
  CorrectionRepository? corrections,
  AdminRepository? admin,
  UserEntity? user,
  HistoryRepository? history,
  PermissionSet? permissions,
}) {
  final account = user ?? testUser();
  final granted =
      permissions ??
      (admin != null
          ? PermissionSet(Permission.all.toSet(), isAdmin: true)
          : PermissionSet.fromRole(account));
  final repo = repository ?? InMemoryAttendanceRepository();
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<HistoryRepository>.value(
        value: history ?? AttendanceHistoryAdapter(repo),
      ),
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
              AuthCubit(FakeAuthRepository(signedInUser: account))..start(),
        ),
        BlocProvider(
          create: (_) => PermissionsCubit(
            const NoPermissionRepository(),
            enabled: false,
            initial: granted,
          ),
        ),
        BlocProvider(create: (_) => ClockCubit()),
        BlocProvider(create: (_) => AttendanceSessionCubit(repo)..load()),
        BlocProvider(create: (_) => LocaleCubit(MemoryLocaleStore())),
      ],
      child: child,
    ),
  );
}

/// Permissions never read from a database (the cubit's role mode).
class NoPermissionRepository implements PermissionRepository {
  const NoPermissionRepository();

  @override
  Future<Set<String>> getMine() async => const {};

  @override
  Future<List<PermissionEntry>> getFor(String userId) async => const [];

  @override
  Future<void> setFor(String userId, Set<String> codes) async {}
}
