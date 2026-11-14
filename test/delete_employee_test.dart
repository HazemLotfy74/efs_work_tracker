import 'dart:async';

import 'package:efs_work_tracker/app/features/admin/data/repositories/supabase_admin_repository.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/employee_entity.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/manager/employee_details_cubit/employee_details_cubit.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/employee_details_view.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/permissions/domain/entities/permission_set.dart';
import 'package:efs_work_tracker/core/errors/admin_errors.dart';
import 'package:efs_work_tracker/core/services/database_services.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/app_providers.dart';
import 'helpers/fake_admin_repository.dart';
import 'helpers/fake_evidence_storage.dart';

const adminId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const monaId = '11111111-1111-4111-8111-111111111111';
const scheduleId = '22222222-2222-4222-8222-222222222222';

EmployeeEntity employee({
  String id = monaId,
  String name = 'Mona Ali',
  UserRole role = UserRole.employee,
}) => EmployeeEntity(
  id: id,
  fullName: name,
  username: 'mona.ali',
  employeeCode: 'EMP-11',
  role: role,
  isActive: true,
  mustChangePassword: false,
  scheduleId: scheduleId,
);

UserEntity account(String id, UserRole role) => UserEntity(
  uID: id,
  email: 'a@example.com',
  fullName: 'Signed In',
  username: 'signed.in',
  employeeCode: 'X-1',
  role: role,
  isActive: true,
  mustChangePassword: false,
);

Map<String, dynamic> profileRow(String id, String name) => {
  'id': id,
  'full_name': name,
  'username': 'u-$id',
  'employee_code': 'C-$id',
  'role': 'employee',
  'is_active': true,
  'must_change_password': false,
  'schedule_id': scheduleId,
  'created_at': '2026-10-20T09:00:00Z',
};

/// `profiles` and the `admin_delete_employee` function of the database.
class _Database extends Fake implements DatabaseServices {
  List<Map<String, dynamic>> rows = [];
  final columns = <String>[];
  final calls = <(String, Map<String, dynamic>?)>[];

  /// What `admin_delete_employee` answers, or throws.
  Object? answer = true;
  Object? error;

  @override
  Future<dynamic> rpc({
    required String function,
    Map<String, dynamic>? params,
  }) async {
    calls.add((function, params));
    if (error case final error?) throw error;
    return answer;
  }

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
    columns.add(column ?? '');
    return [
      for (final row in rows)
        if (query == null || query['id'] == row['id']) row,
    ];
  }
}

Future<void> show(
  WidgetTester tester,
  FakeAdminRepository admin, {
  required UserEntity user,
  PermissionSet? permissions,
  Locale locale = const Locale('en'),
  Size size = const Size(430, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    withAppProviders(
      MaterialApp(
        theme: AppTheme.lightFor(locale),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // A page underneath, like the employee list, to return to.
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          const EmployeeDetailsView(id: monaId, name: 'Mona'),
                    ),
                  );
                  returned = changed;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
      admin: admin,
      user: user,
      permissions: permissions,
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// What the employee page handed back to the list when it closed.
bool? returned;

FakeAdminRepository repositoryWith(EmployeeEntity target) =>
    FakeAdminRepository()
      ..employees = [target]
      ..schedules = const [
        WorkScheduleOption(
          id: scheduleId,
          name: 'Morning',
          timezone: 'Africa/Cairo',
        ),
      ];

void main() {
  setUp(() => returned = null);

  group('SupabaseAdminRepository.deleteEmployee', () {
    late _Database db;
    final accountCalls = <Map<String, dynamic>>[];
    SupabaseAdminRepository repository({String? me = adminId}) =>
        SupabaseAdminRepository(
          storageServices: FakeEvidenceStorage(),
          databaseServices: db,
          accountsFunction: (body) async {
            accountCalls.add(body);
            return null;
          },
          currentUserId: () => me,
        );

    setUp(() {
      db = _Database();
      accountCalls.clear();
    });

    test('calls admin_delete_employee with the employee id only', () async {
      await repository().deleteEmployee(monaId);
      expect(db.calls.single.$1, 'admin_delete_employee');
      expect(db.calls.single.$2, {'p_employee_id': monaId});
      expect(accountCalls, isEmpty, reason: 'not the edge function');
    });

    test('never asks the server to delete the signed-in account', () async {
      await expectLater(
        repository().deleteEmployee(adminId),
        throwsA(AdminFailure.notAllowed),
      );
      expect(db.calls, isEmpty);
    });

    test('signed out: nothing is sent', () async {
      await expectLater(
        repository(me: null).deleteEmployee(monaId),
        throwsA(AdminFailure.notAllowed),
      );
      expect(db.calls, isEmpty);
    });

    test('false from the database: there is no such employee', () async {
      db.answer = false;
      await expectLater(
        repository().deleteEmployee(monaId),
        throwsA(AdminFailure.notFound),
      );
    });

    test('server answers become clear failures', () async {
      Future<void> expectFailure(Object error, AdminFailure failure) async {
        db.error = error;
        await expectLater(
          repository().deleteEmployee(monaId),
          throwsA(failure),
          reason: '$error',
        );
      }

      // Not an admin, or the target is an admin.
      await expectFailure(
        const PostgrestException(
          message: 'Only employee accounts can be deleted',
          code: '42501',
        ),
        AdminFailure.notAllowed,
      );
      // Attendance, requests, evidence, notifications or devices exist.
      await expectFailure(
        const PostgrestException(
          message:
              'Employee has linked records. Deactivate this employee to '
              'retain their history.',
          code: 'PT409',
        ),
        AdminFailure.hasHistory,
      );
      // The function is missing from the database.
      await expectFailure(
        const PostgrestException(message: 'not found', code: 'PGRST202'),
        AdminFailure.serviceUnavailable,
      );
      await expectFailure(TimeoutException('slow'), AdminFailure.outcomeUnknown);
    });

    test('the employee list reads only columns the database has', () async {
      db.rows = [profileRow('a', 'Active One')];
      final repo = repository();
      expect((await repo.getEmployees()).single.fullName, 'Active One');
      expect(await repo.getEmployee('b'), isNull);
      expect(db.columns.where((c) => c.contains('deleted_at')), isEmpty);
    });
  });

  group('EmployeeDetailsCubit.delete', () {
    test('success: busy until the page closes; nothing is reloaded', () async {
      final admin = repositoryWith(employee());
      final cubit = EmployeeDetailsCubit(admin, monaId);
      addTearDown(cubit.close);
      await cubit.load();
      expect(await cubit.delete(), isNull);
      expect(admin.deleted, [monaId]);
      expect((cubit.state as EmployeeDetailsLoaded).busy, isTrue);
    });

    test('failure: the employee stays, and can be tried again', () async {
      final admin = repositoryWith(employee());
      final cubit = EmployeeDetailsCubit(admin, monaId);
      addTearDown(cubit.close);
      await cubit.load();
      admin.failure = AdminFailure.outcomeUnknown;
      expect(await cubit.delete(), AdminFailure.outcomeUnknown);
      admin.failure = null;
      await cubit.load();
      final state = cubit.state as EmployeeDetailsLoaded;
      expect(state.busy, isFalse);
      expect(state.employee.id, monaId);
      expect(admin.deleted, isEmpty);
    });

    test('a double tap deletes once', () async {
      final admin = repositoryWith(employee())..gate = Completer<void>();
      final cubit = EmployeeDetailsCubit(admin, monaId);
      addTearDown(cubit.close);
      admin.gate!.complete();
      await cubit.load();
      admin.gate = Completer<void>();
      final first = cubit.delete();
      expect(await cubit.delete(), AdminFailure.busy);
      admin.gate!.complete();
      expect(await first, isNull);
      expect(admin.deleted, [monaId]);
    });
  });

  group('Employee page', () {
    final adminUser = account(adminId, UserRole.admin);

    testWidgets('an admin sees Delete on an employee; nothing happens on open', (
      tester,
    ) async {
      final admin = repositoryWith(employee());
      await show(tester, admin, user: adminUser);
      expect(find.byKey(const Key('deleteEmployee')), findsOneWidget);
      expect(find.text('Delete employee account'), findsOneWidget);
      expect(admin.deleted, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an employee never sees it, with or without reviewer permissions', (
      tester,
    ) async {
      for (final permissions in [
        const PermissionSet({}),
        const PermissionSet({
          Permission.reviewAssignedCash,
          Permission.reviewAssignedCorrections,
          Permission.reviewAssignedOvertime,
        }),
      ]) {
        await show(
          tester,
          repositoryWith(employee()),
          user: account('someone-else', UserRole.employee),
          permissions: permissions,
        );
        expect(find.byKey(const Key('deleteEmployee')), findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('an admin account, and your own account, have no Delete', (
      tester,
    ) async {
      await show(
        tester,
        repositoryWith(employee(role: UserRole.admin)),
        user: adminUser,
      );
      expect(find.byKey(const Key('deleteEmployee')), findsNothing);
      await tester.pumpWidget(const SizedBox());

      // Opening your own profile as the signed-in account.
      await show(
        tester,
        repositoryWith(employee()),
        user: account(monaId, UserRole.admin),
      );
      expect(find.byKey(const Key('deleteEmployee')), findsNothing);
    });

    testWidgets('the warning names the employee; Cancel deletes nothing', (
      tester,
    ) async {
      final admin = repositoryWith(employee());
      await show(tester, admin, user: adminUser);
      await tester.tap(find.byKey(const Key('deleteEmployee')));
      await tester.pumpAndSettle();

      expect(find.text('Permanently delete employee account'), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsWidgets);
      expect(find.text('Employee: Mona Ali'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cancelDelete')));
      await tester.pumpAndSettle();
      expect(admin.deleted, isEmpty);
      expect(find.byKey(const Key('deleteEmployee')), findsOneWidget);
      expect(returned, isNull, reason: 'still on the employee page');
    });

    testWidgets('one stray tap is not enough: the box must be ticked first', (
      tester,
    ) async {
      final admin = repositoryWith(employee());
      await show(tester, admin, user: adminUser);
      await tester.tap(find.byKey(const Key('deleteEmployee')));
      await tester.pumpAndSettle();

      FilledButton confirm() => tester.widget(
        find.descendant(
          of: find.byKey(const Key('confirmDelete')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(confirm().onPressed, isNull);
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await tester.pumpAndSettle();
      expect(admin.deleted, isEmpty);

      // Dismissing by tapping outside is a cancel too.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(admin.deleted, isEmpty);
    });

    testWidgets('confirmed: progress while it runs, then success and back', (
      tester,
    ) async {
      final admin = repositoryWith(employee());
      await show(tester, admin, user: adminUser);
      await tester.tap(find.byKey(const Key('deleteEmployee')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deleteAcknowledge')));
      await tester.pump();

      admin.gate = Completer<void>();
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // The server has not answered: the employee is still shown, the
      // action is locked and progress is visible.
      expect(find.text('Mona Ali'), findsOneWidget);
      expect(find.byKey(const Key('employeeBusy')), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('deleteEmployee')))
            .onPressed,
        isNull,
      );
      expect(admin.deleted, isEmpty);

      admin.gate!.complete();
      await tester.pumpAndSettle();
      expect(admin.deleted, [monaId]);
      expect(
        find.text('The employee account was permanently deleted.'),
        findsOneWidget,
      );
      expect(returned, isTrue, reason: 'the list is told to reload');
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('a failed deletion keeps the employee and says why', (
      tester,
    ) async {
      final admin = repositoryWith(employee());
      await show(tester, admin, user: adminUser);
      await tester.tap(find.byKey(const Key('deleteEmployee')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deleteAcknowledge')));
      await tester.pump();
      admin.failure = AdminFailure.notAllowed;
      await tester.tap(find.byKey(const Key('confirmDelete')));
      await tester.pump();
      admin.failure = null;
      await tester.pumpAndSettle();

      expect(admin.deleted, isEmpty);
      expect(returned, isNull);
      expect(find.byKey(const Key('appSnackBar')), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('42501'), findsNothing);
      expect(find.byKey(const Key('deleteEmployee')), findsOneWidget);
    });

    testWidgets('Arabic, small phone, large text: the asked wording, no overflow', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(
        tester,
        repositoryWith(employee(name: 'منى علي عبد الرحمن')),
        user: adminUser,
        locale: const Locale('ar'),
        size: const Size(320, 1400),
      );
      expect(find.text('حذف حساب الموظف'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'the page itself');
      await tester.tap(find.byKey(const Key('deleteEmployee')));
      await tester.pumpAndSettle();
      expect(find.text('حذف حساب الموظف نهائياً'), findsOneWidget);
      expect(
        find.textContaining('لا يمكن التراجع عن هذا الإجراء بعد تنفيذه.'),
        findsOneWidget,
      );
      expect(find.text('الموظف: منى علي عبد الرحمن'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('حذف نهائياً'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
