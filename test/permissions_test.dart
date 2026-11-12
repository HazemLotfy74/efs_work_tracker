import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/permissions/data/repositories/supabase_permission_repository.dart';
import 'package:efs_work_tracker/app/features/permissions/domain/entities/permission_set.dart';
import 'package:efs_work_tracker/app/features/permissions/domain/repositories/permission_repository.dart';
import 'package:efs_work_tracker/app/features/permissions/presentation/manager/manage_permissions_cubit.dart';
import 'package:efs_work_tracker/app/features/permissions/presentation/manager/permissions_cubit.dart';
import 'package:efs_work_tracker/app/features/permissions/presentation/views/manage_permissions_view.dart';
import 'package:efs_work_tracker/core/errors/admin_errors.dart';
import 'package:efs_work_tracker/core/router/app_router.dart';
import 'package:efs_work_tracker/core/router/app_routes.dart';
import 'package:efs_work_tracker/core/services/database_services.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/app_providers.dart';
import 'helpers/fake_admin_repository.dart';
import 'helpers/fake_auth_repository.dart';

const admin = UserEntity(
  uID: 'admin-1',
  email: 'admin@example.com',
  fullName: 'Test Admin',
  username: 'test.admin',
  employeeCode: 'ADM-1',
  role: UserRole.admin,
  isActive: true,
  mustChangePassword: false,
);

PermissionEntry entry(
  String code, {
  bool fromRole = false,
  bool granted = false,
  bool canChange = true,
  bool sensitive = false,
}) => PermissionEntry(
  code: code,
  category: code.split('.').first == 'audit'
      ? 'employees'
      : code.split('.').first,
  sensitive: sensitive,
  fromRole: fromRole,
  granted: granted,
  canChange: canChange,
  grantedAt: granted ? DateTime.utc(2026, 11, 10, 9) : null,
);

class FakePermissionRepository implements PermissionRepository {
  Set<String> mine = {};
  List<PermissionEntry> entries = [];
  AdminFailure? failure;
  final saved = <(String, Set<String>)>[];

  @override
  Future<Set<String>> getMine() async {
    if (failure case final failure?) throw failure;
    return mine;
  }

  @override
  Future<List<PermissionEntry>> getFor(String userId) async {
    if (failure case final failure?) throw failure;
    return [
      for (final e in entries)
        PermissionEntry(
          code: e.code,
          category: e.category,
          sensitive: e.sensitive,
          fromRole: e.fromRole,
          granted: saved.isEmpty ? e.granted : saved.last.$2.contains(e.code),
          canChange: e.canChange,
        ),
    ];
  }

  @override
  Future<void> setFor(String userId, Set<String> codes) async {
    if (failure case final failure?) throw failure;
    saved.add((userId, codes));
  }
}

void main() {
  group('PermissionSet', () {
    test('before the migration the role decides', () {
      final adminSet = PermissionSet.fromRole(admin);
      expect(adminSet.isAdmin, isTrue);
      expect(adminSet.codes, Permission.all.toSet());
      expect(adminSet.hasAdminArea, isTrue);

      final employee = PermissionSet.fromRole(testUser());
      expect(employee.codes, isEmpty);
      expect(employee.hasAdminArea, isFalse);
      expect(PermissionSet.fromRole(null), PermissionSet.none);
    });
  });

  group('route guard', () {
    final signedIn = AuthSignedIn(testUser());
    String? at(String route, PermissionSet permissions) =>
        AppRouter.redirectFor(signedIn, route, permissions: permissions);

    test('each admin screen needs its own permission', () {
      const cashOnly = PermissionSet({Permission.cashViewAll});
      expect(at(AppRoutes.adminDashboard, cashOnly), isNull);
      expect(at(AppRoutes.adminRequests, cashOnly), isNull);
      for (final route in [
        AppRoutes.adminCorrections,
        AppRoutes.adminReports,
        AppRoutes.adminAddEmployee,
        AppRoutes.adminEmployee,
        AppRoutes.adminEmployeeAudit,
        AppRoutes.adminEmployeePermissions,
        AppRoutes.adminAttendanceDay,
        AppRoutes.adminEditAttendance,
      ]) {
        expect(at(route, cashOnly), AppRoutes.home, reason: route);
      }
      // Self-service stays open.
      expect(at(AppRoutes.cashRequest, PermissionSet.none), isNull);
    });

    test('no permission: no admin area; admin role: everything', () {
      expect(at(AppRoutes.adminDashboard, PermissionSet.none), AppRoutes.home);
      final everything = PermissionSet.fromRole(admin);
      for (final route in [
        AppRoutes.adminDashboard,
        AppRoutes.adminAddEmployee,
        AppRoutes.adminEmployeePermissions,
        AppRoutes.adminEditAttendance,
      ]) {
        expect(at(route, everything), isNull, reason: route);
      }
    });

    test('account creation stays with the admin role', () {
      final allCodes = PermissionSet(Permission.all.toSet());
      expect(at(AppRoutes.adminAddEmployee, allCodes), AppRoutes.home);
    });
  });

  group('PermissionsCubit', () {
    late FakePermissionRepository repository;
    setUp(() => repository = FakePermissionRepository());

    test('switched off: the role decides, nothing is read', () async {
      repository.failure = AdminFailure.network; // would fail if read
      final cubit = PermissionsCubit(repository, enabled: false);
      addTearDown(cubit.close);
      await cubit.userChanged(admin);
      expect(cubit.state, PermissionSet.fromRole(admin));
      await cubit.userChanged(testUser());
      expect(cubit.state.codes, isEmpty);
    });

    test('switched on: read from the database, refreshed', () async {
      repository.mine = {Permission.cashViewAll, Permission.cashApprove};
      final cubit = PermissionsCubit(repository, enabled: true);
      addTearDown(cubit.close);
      await cubit.userChanged(testUser());
      expect(cubit.state.codes, repository.mine);

      // A revoked grant disappears on the next refresh.
      repository.mine = {Permission.cashViewAll};
      await cubit.refresh();
      expect(cubit.state.codes, {Permission.cashViewAll});

      await cubit.userChanged(null);
      expect(cubit.state, PermissionSet.none);
    });

    test(
      'a failed read falls back to the role, never to another account',
      () async {
        repository.mine = {Permission.cashViewAll};
        final cubit = PermissionsCubit(repository, enabled: true);
        addTearDown(cubit.close);
        await cubit.userChanged(testUser());
        expect(cubit.state.codes, {Permission.cashViewAll});

        repository.failure = AdminFailure.network;
        await cubit.userChanged(
          const UserEntity(
            uID: 'other',
            email: 'o@example.com',
            fullName: 'Other',
            username: 'other',
            employeeCode: 'EMP-9',
            role: UserRole.employee,
            isActive: true,
            mustChangePassword: false,
          ),
        );
        expect(cubit.state.codes, isEmpty);
      },
    );
  });

  group('SupabasePermissionRepository (live reviewer flags)', () {
    _ProfilesDatabase database({String role = 'employee'}) =>
        _ProfilesDatabase({
          'role': role,
          'can_review_expense_advances': true,
          'can_review_attendance_corrections': false,
          'can_review_overtime': false,
        });
    SupabasePermissionRepository repositoryOn(_ProfilesDatabase db) =>
        SupabasePermissionRepository(
          databaseServices: db,
          currentUserId: () => 'emp-1',
        );

    test('my flags become codes, read from my own profile row', () async {
      final db = database();
      expect(await repositoryOn(db).getMine(), {Permission.reviewAssignedCash});
      expect(db.reads.single, {'id': 'emp-1'});
    });

    test('an employee: three switches, changeable; an admin: locked', () async {
      final entries = await repositoryOn(database()).getFor('emp-2');
      expect(entries.map((e) => e.code), Permission.delegable.keys);
      expect(entries.every((e) => e.canChange && !e.fromRole), isTrue);
      expect(
        entries.singleWhere((e) => e.granted).code,
        Permission.reviewAssignedCash,
      );

      final admin = await repositoryOn(database(role: 'admin')).getFor('adm');
      expect(admin.any((e) => e.canChange), isFalse);
    });

    test('saving calls only the functions of the flags that changed', () async {
      final db = database();
      await repositoryOn(db)
          .setFor('emp-2', {Permission.reviewAssignedCorrections});
      expect(db.calls, [
        ('admin_set_expense_advance_reviewer_permission', 'emp-2', false),
        ('admin_set_attendance_correction_reviewer_permission', 'emp-2', true),
      ]);
    });

    test('server refusals become admin failures', () async {
      final db = database()
        ..error = const PostgrestException(
          message: 'An active, password-ready authorized account is required',
          code: '42501',
        );
      await expectLater(
        repositoryOn(db).setFor('emp-2', {}),
        throwsA(AdminFailure.notAllowed),
      );
    });

    test(
      'a missing profile is "not found", signed out is "not allowed"',
      () async {
        final db = _ProfilesDatabase(null);
        await expectLater(
          repositoryOn(db).getFor('nobody'),
          throwsA(AdminFailure.notFound),
        );
        final signedOut = SupabasePermissionRepository(
          databaseServices: db,
          currentUserId: () => null,
        );
        await expectLater(
          signedOut.getMine(),
          throwsA(AdminFailure.notAllowed),
        );
      },
    );
  });

  group('ManagePermissionsCubit', () {
    late FakePermissionRepository repository;
    setUp(() {
      repository = FakePermissionRepository()
        ..entries = [
          entry(Permission.cashViewAll, granted: true),
          entry(Permission.cashApprove),
          entry(Permission.auditView, canChange: false, sensitive: true),
        ];
    });

    test(
      'edits, shows the difference and saves exactly the selection',
      () async {
        final cubit = ManagePermissionsCubit(repository, 'emp-1');
        addTearDown(cubit.close);
        await cubit.load();
        var state = cubit.state as ManagePermissionsLoaded;
        expect(state.selected, {Permission.cashViewAll});
        expect(state.hasChanges, isFalse);

        cubit.toggle(Permission.cashApprove, true);
        cubit.toggle(Permission.cashViewAll, false);
        cubit.toggle(Permission.auditView, true); // not the manager's to give
        state = cubit.state as ManagePermissionsLoaded;
        expect(state.added, {Permission.cashApprove});
        expect(state.removed, {Permission.cashViewAll});

        expect(await cubit.save(), isNull);
        expect(repository.saved.single.$1, 'emp-1');
        expect(repository.saved.single.$2, {Permission.cashApprove});
        state = cubit.state as ManagePermissionsLoaded;
        expect(state.hasChanges, isFalse);
        expect(state.selected, {Permission.cashApprove});
      },
    );

    test('a refused save keeps the edits', () async {
      final cubit = ManagePermissionsCubit(repository, 'emp-1');
      addTearDown(cubit.close);
      await cubit.load();
      cubit.toggle(Permission.cashApprove, true);
      repository.failure = AdminFailure.notAllowed;
      expect(await cubit.save(), AdminFailure.notAllowed);
      final state = cubit.state as ManagePermissionsLoaded;
      expect(state.added, {Permission.cashApprove});
      expect(state.saving, isFalse);
    });
  });

  group('screens', () {
    Future<void> pump(
      WidgetTester tester,
      Widget home, {
      PermissionSet? permissions,
      PermissionRepository? repository,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        withAppProviders(
          user: permissions?.isAdmin ?? false ? admin : testUser(),
          permissions: permissions,
          admin: FakeAdminRepository(),
          RepositoryProvider<PermissionRepository>.value(
            value: repository ?? FakePermissionRepository(),
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: home,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a cash-only delegate sees only the cash tool', (tester) async {
      await pump(
        tester,
        const AdminDashboardView(),
        permissions: const PermissionSet({Permission.cashViewAll}),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('adminRequests')), findsOneWidget);
      expect(find.byKey(const Key('adminAddEmployee')), findsNothing);
      expect(find.byKey(const Key('adminCorrections')), findsNothing);
      expect(find.byKey(const Key('adminReports')), findsNothing);
      // No employee overview without employees.view + attendance.view_all.
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('managing an employee: role, grants, limits, save', (
      tester,
    ) async {
      final repository = FakePermissionRepository()
        ..entries = [
          entry(Permission.cashViewAll, granted: true),
          entry(Permission.cashApprove),
          entry(
            Permission.managePermissions,
            canChange: false,
            sensitive: true,
          ),
        ];
      await pump(
        tester,
        const ManagePermissionsView(employeeId: 'emp-1', name: 'Mona Ali'),
        permissions: PermissionSet.fromRole(admin),
        repository: repository,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Permissions · Mona Ali'), findsOneWidget);
      expect(find.text("See everyone's cash requests"), findsOneWidget);
      expect(
        find.text('Only an administrator can change this'),
        findsOneWidget,
      );
      final locked = tester.widget<SwitchListTile>(
        find.byKey(Key('permission-${Permission.managePermissions}')),
      );
      expect(locked.onChanged, isNull);

      await tester.tap(find.byKey(Key('permission-${Permission.cashApprove}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('savePermissions')));
      await tester.pumpAndSettle();
      // The confirmation lists the change before anything is saved.
      expect(find.textContaining('Will be granted'), findsOneWidget);
      expect(repository.saved, isEmpty);
      await tester.tap(find.text('Review and save').last);
      await tester.pumpAndSettle();
      expect(repository.saved.single.$1, 'emp-1');
      expect(repository.saved.single.$2, {
        Permission.cashViewAll,
        Permission.cashApprove,
      });
      expect(find.text('Permissions saved'), findsOneWidget);
    });
  });
}

/// One `profiles` row with its reviewer flags, and the admin functions that
/// change them.
class _ProfilesDatabase implements DatabaseServices {
  _ProfilesDatabase(this.row);

  final Map<String, Object?>? row;

  /// Makes every function call fail.
  Exception? error;
  final reads = <Map<String, dynamic>?>[];
  final calls = <(String, String, bool)>[];

  @override
  Future<dynamic> getData({
    required String path,
    String? documentId,
    String? column,
    Map<String, dynamic>? query,
    String? orderBy,
    bool descending = false,
    int? limit,
    Map<String, Object>? greaterThanOrEqual,
    Map<String, Object>? lessThan,
  }) async {
    expect(path, 'profiles');
    reads.add(query);
    return [?row];
  }

  @override
  Future<dynamic> rpc({
    required String function,
    Map<String, dynamic>? params,
  }) async {
    if (error case final error?) throw error;
    calls.add((
      function,
      params!['p_employee_id'] as String,
      params['p_enabled'] as bool,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
