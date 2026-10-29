import 'dart:async';

import 'package:efs_work_tracker/app/features/admin/data/repositories/supabase_admin_repository.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/admin_request_entity.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/employee_entity.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/manager/add_employee_cubit/add_employee_cubit.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/manager/admin_dashboard_cubit/admin_dashboard_cubit.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/manager/admin_requests_cubit/admin_requests_cubit.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/add_employee_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_requests_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/attendance_session_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/shift_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/profile/presentation/widgets/profile_view_body.dart';
import 'package:efs_work_tracker/core/errors/admin_errors.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/core/manager/locale_cubit.dart';
import 'package:efs_work_tracker/core/services/accounts_function.dart';
import 'package:efs_work_tracker/core/services/database_services.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/app_providers.dart';
import 'helpers/fake_admin_repository.dart';

// Cairo is UTC+3 until 29 October 2026: 12:00 Cairo on Sunday 25 October.
const adminId = '33333333-3333-4333-8333-333333333333';
const monaId = '11111111-1111-4111-8111-111111111111';
const scheduleId = '44444444-4444-4444-8444-444444444444';
final midday = DateTime.utc(2026, 10, 25, 9);
final evening = DateTime.utc(2026, 10, 25, 15); // 18:00 Cairo
final shiftStart = DateTime.utc(2026, 10, 25, 5);
final shiftEnd = DateTime.utc(2026, 10, 25, 13);

Map<String, dynamic> profileRow(
  String id,
  String name, {
  String role = 'employee',
}) => {
  'id': id,
  'full_name': name,
  'username': name.toLowerCase().replaceAll(' ', '.'),
  'employee_code': 'EMP-${id.substring(0, 2)}',
  'role': role,
  'is_active': true,
  'must_change_password': false,
  'schedule_id': scheduleId,
};

Map<String, dynamic> recordRow(String employeeId, {DateTime? checkOut}) => {
  'id': 'record-$employeeId',
  'employee_id': employeeId,
  'work_date': '2026-10-25',
  'timezone': 'Africa/Cairo',
  'scheduled_start': shiftStart.toIso8601String(),
  'scheduled_end': shiftEnd.toIso8601String(),
  'grace_minutes': 15,
  'actual_checkin': DateTime.utc(2026, 10, 25, 5, 7).toIso8601String(),
  'actual_checkout': checkOut?.toIso8601String(),
  'auto_closed': false,
  'auto_closed_at': null,
  'auto_close_policy': 'midnight',
  'auto_close_deadline': DateTime.utc(2026, 10, 25, 21).toIso8601String(),
  'effective_checkin': null,
  'effective_checkout': null,
  'has_correction': false,
  'late_minutes': 0,
  'attendance_events': <Map<String, dynamic>>[],
};

AttendanceSessionEntity sessionOf(Map<String, dynamic> json) =>
    AttendanceSessionModel.fromJson(json, shift: ShiftModel.fromRecord(json));

EmployeeEntity employee(String id, String name, {bool active = true}) =>
    EmployeeEntity(
      id: id,
      fullName: name,
      username: name.toLowerCase().replaceAll(' ', '.'),
      employeeCode: 'EMP-${id.substring(0, 2)}',
      role: UserRole.employee,
      isActive: active,
      mustChangePassword: false,
      scheduleId: scheduleId,
    );

NewEmployeeDraft draft({String username = 'sara.k'}) => NewEmployeeDraft(
  fullName: ' Sara Kamal ',
  username: username,
  email: ' Sara@Example.com ',
  employeeCode: 'emp-9',
  scheduleId: scheduleId,
  password: 'a-long-first-password',
);

AdminRequestEntity cashRequest({String id = 'cash-1'}) => AdminRequestEntity(
  id: id,
  employeeId: monaId,
  employeeName: 'Mona Ali',
  employeeCode: 'EMP-11',
  reason: 'Printer toner',
  createdAt: midday,
  amount: 250.5,
  currency: 'EGP',
);

/// The existing tables as an admin reads them through RLS, plus
/// `review_request`. Never connects to a real database.
class FakeAdminServer implements DatabaseServices {
  final tables = <String, List<Map<String, dynamic>>>{
    'profiles': [
      profileRow(monaId, 'Mona Ali'),
      profileRow(adminId, 'Test Admin', role: 'admin'),
    ],
    'work_schedules': [
      {'id': scheduleId, 'name': 'Standard', 'timezone': 'Africa/Cairo'},
    ],
    'attendance_records': [recordRow(monaId)],
    'expense_advance_requests': [],
  };
  final reads = <(String, String?, Map<String, dynamic>?)>[];
  final rpcCalls = <(String, Map<String, dynamic>?)>[];
  Object? nextError;

  @override
  Future<dynamic> getData({
    required String path,
    String? documentId,
    String? column,
    Map<String, dynamic>? query,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    reads.add((path, column, query));
    if (nextError case final error?) {
      nextError = null;
      throw error;
    }
    final rows = tables[path] ?? (throw UnimplementedError(path));
    final embed = column?.contains('employee:profiles!') ?? false;
    return [
      for (final row in rows)
        if (query?.entries.every((e) => row[e.key] == e.value) ?? true)
          {
            ...row,
            if (embed)
              'employee': {'full_name': 'Mona Ali', 'employee_code': 'EMP-11'},
          },
    ];
  }

  @override
  Future<dynamic> rpc({
    required String function,
    Map<String, dynamic>? params,
  }) async {
    rpcCalls.add((function, params));
    if (nextError case final error?) {
      nextError = null;
      throw error;
    }
    return null;
  }

  @override
  Future<void> addData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) => throw UnimplementedError('table write');

  @override
  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) => throw UnimplementedError('table write');

  @override
  Future<void> deleteData({
    required String path,
    String? documentId,
    Map<String, dynamic>? query,
  }) => throw UnimplementedError('table write');

  @override
  Stream<dynamic> getStreamData({
    required String path,
    String? documentId,
    Map<String, dynamic>? query,
  }) => throw UnimplementedError();

  @override
  Future<bool> ifDataExist({
    required String path,
    required String documentId,
  }) => throw UnimplementedError();
}

/// `employee-accounts` `create_employee`: idempotent by request id.
class FakeAccountsFunction {
  final calls = <Map<String, dynamic>>[];
  final _created = <String, String>{};
  Object? nextError;

  Future<Object?> call(Map<String, dynamic> body) async {
    calls.add(body);
    if (nextError case final error?) {
      nextError = null;
      throw error;
    }
    final id = _created.putIfAbsent(
      body['request_id'] as String,
      () => 'employee-${_created.length + 1}',
    );
    return {'id': id, 'replayed': false, 'must_change_password': true};
  }
}

void main() {
  group('NewEmployeeDraft', () {
    test('normalizes like the Edge Function', () {
      final value = draft();
      expect(value.fullName, 'Sara Kamal');
      expect(value.email, 'sara@example.com');
      expect(value.employeeCode, 'EMP-9');
      expect(value.invalidFields, isEmpty);
    });

    test('flags what the Edge Function would refuse', () {
      final value = NewEmployeeDraft(
        fullName: ' ',
        username: 'a',
        email: 'nope',
        employeeCode: '-',
        scheduleId: null,
        password: 'short',
      );
      expect(value.invalidFields, NewEmployeeField.values.toSet());
      expect(
        NewEmployeeDraft(
          fullName: 'x',
          username: 'abc',
          email: 'a@b.co',
          employeeCode: 'AB',
          scheduleId: scheduleId,
          password: 'é' * 37, // 37 characters, 74 bytes
        ).invalidFields,
        {NewEmployeeField.password},
      );
    });
  });

  group('SupabaseAdminRepository', () {
    late FakeAdminServer server;
    late FakeAccountsFunction accounts;
    late SupabaseAdminRepository repository;

    setUp(() {
      server = FakeAdminServer();
      accounts = FakeAccountsFunction();
      repository = SupabaseAdminRepository(
        databaseServices: server,
        accountsFunction: accounts.call,
        currentUserId: () => adminId,
        now: () => DateTime.utc(2026, 10, 24, 22, 30), // 01:30 Cairo, Sunday
      );
    });

    test('today is the work date in the schedule’s timezone', () async {
      final employees = await repository.getEmployees();
      final schedules = await repository.getSchedules();
      final today = await repository.getToday(employees, schedules);
      expect(server.reads.last.$3, {'work_date': '2026-10-25'});
      expect(today.keys, [monaId]);
      expect(today[monaId]!.timezone, 'Africa/Cairo');
      expect(employees.map((e) => e.fullName), ['Mona Ali', 'Test Admin']);
    });

    test('history reads one employee’s days', () async {
      final days = await repository.getHistory(monaId);
      expect(days, hasLength(1));
      expect(server.reads.last.$3, {'employee_id': monaId});
    });

    test('pending cash requests, without the admin’s own', () async {
      server.tables['expense_advance_requests'] = [
        {
          'id': 'cash-1',
          'employee_id': monaId,
          'requested_amount': '250.50',
          'currency': 'EGP',
          'reason': 'Toner',
          'status': 'pending',
          'created_at': evening.toIso8601String(),
        },
        {
          'id': 'cash-own',
          'employee_id': adminId,
          'requested_amount': 10,
          'currency': 'EGP',
          'reason': 'Mine',
          'status': 'pending',
          'created_at': midday.toIso8601String(),
        },
      ];
      final requests = await repository.getPendingRequests();
      expect(requests.map((r) => r.id), ['cash-1']);
      expect(requests.single.amount, 250.5);
      expect(requests.single.employeeName, 'Mona Ali');
      expect(server.reads.single.$1, 'expense_advance_requests');
      expect(
        server.reads.single.$2,
        contains('expense_advance_requests_employee_id_fkey'),
      );
      // Overtime has no requests to review: it is calculated.
      expect(
        server.reads.map((r) => r.$1),
        isNot(contains('overtime_requests')),
      );
    });

    test('review sends the request’s kind and a trimmed note', () async {
      await repository.review(cashRequest(), approve: false, note: '  ');
      expect(server.rpcCalls.single.$1, 'review_request');
      expect(server.rpcCalls.single.$2, {
        'p_kind': 'expense_advance',
        'p_request_id': 'cash-1',
        'p_approve': false,
        'p_note': null,
      });

      server.nextError = const PostgrestException(
        message: 'This request has already been reviewed',
        code: 'P0001',
      );
      await expectLater(
        repository.review(cashRequest(), approve: true),
        throwsA(AdminFailure.alreadyReviewed),
      );
    });

    test('create_employee sends the normalized draft and request id', () async {
      final id = await repository.createEmployee(draft(), requestId: 'req-1');
      expect(id, 'employee-1');
      expect(accounts.calls.single, {
        'action': 'create_employee',
        'request_id': 'req-1',
        'full_name': 'Sara Kamal',
        'username': 'sara.k',
        'email': 'sara@example.com',
        'password': 'a-long-first-password',
        'employee_code': 'EMP-9',
        'schedule_id': scheduleId,
      });
    });

    test('a lost answer is outcome-unknown, and retrying is safe', () async {
      accounts.nextError = TimeoutException('lost');
      await expectLater(
        repository.createEmployee(draft(), requestId: 'req-1'),
        throwsA(AdminFailure.outcomeUnknown),
      );
      expect(
        await repository.createEmployee(draft(), requestId: 'req-1'),
        await repository.createEmployee(draft(), requestId: 'req-1'),
      );
    });

    test('Edge Function errors', () {
      expect(
        SupabaseAdminRepository.accountFailureFor(409, 'account_conflict'),
        AdminFailure.accountConflict,
      );
      expect(
        SupabaseAdminRepository.accountFailureFor(403, 'forbidden'),
        AdminFailure.notAllowed,
      );
      expect(
        SupabaseAdminRepository.accountFailureFor(400, 'invalid_input'),
        AdminFailure.invalidInput,
      );
      expect(
        SupabaseAdminRepository.accountFailureFor(503, 'outcome_unknown'),
        AdminFailure.outcomeUnknown,
      );
      expect(
        SupabaseAdminRepository.accountFailureFor(
          429,
          'over_request_rate_limit',
        ),
        AdminFailure.tooManyRequests,
      );
    });

    test('an invalid draft is never sent', () async {
      await expectLater(
        repository.createEmployee(draft(username: 'x'), requestId: 'req-1'),
        throwsA(AdminFailure.invalidInput),
      );
      expect(accounts.calls, isEmpty);
    });

    test(
      'no answer: refused by the browser on web, unknown on a phone',
      () async {
        const noAnswer = AccountsFunctionException(
          0,
          AccountsFunctionException.unreachable,
        );
        SupabaseAdminRepository on({required bool web}) =>
            SupabaseAdminRepository(
              databaseServices: server,
              accountsFunction: accounts.call,
              currentUserId: () => adminId,
              isWeb: web,
            );
        accounts.nextError = noAnswer;
        await expectLater(
          on(web: true).createEmployee(draft(), requestId: 'req-1'),
          throwsA(AdminFailure.webOriginBlocked),
        );
        accounts.nextError = noAnswer;
        await expectLater(
          on(web: false).createEmployee(draft(), requestId: 'req-1'),
          throwsA(AdminFailure.outcomeUnknown),
        );
      },
    );

    test('a function error answer becomes a failure', () async {
      accounts.nextError = const AccountsFunctionException(
        409,
        'account_conflict',
      );
      await expectLater(
        repository.createEmployee(draft(), requestId: 'req-1'),
        throwsA(AdminFailure.accountConflict),
      );
    });

    test('database errors', () {
      expect(
        SupabaseAdminRepository.failureFor(
          '42501',
          'An active, password-ready authorized account is required',
        ),
        AdminFailure.notAllowed,
      );
      expect(
        SupabaseAdminRepository.failureFor(
          '42501',
          'You cannot review your own request',
        ),
        AdminFailure.ownRequest,
      );
      expect(
        SupabaseAdminRepository.failureFor('22023', 'Request not found'),
        AdminFailure.notFound,
      );
    });

    test('signed out: nothing is read', () async {
      final signedOut = SupabaseAdminRepository(
        databaseServices: server,
        accountsFunction: accounts.call,
        currentUserId: () => null,
      );
      await expectLater(
        signedOut.getEmployees(),
        throwsA(AdminFailure.notAllowed),
      );
      expect(server.reads, isEmpty);
    });
  });

  group('AddEmployeeCubit', () {
    test('a retry of the same details reuses the request id', () async {
      final repository = FakeAdminRepository()
        ..schedules = [
          const WorkScheduleOption(
            id: scheduleId,
            name: 'Standard',
            timezone: 'Africa/Cairo',
          ),
        ];
      var ids = 0;
      final cubit = AddEmployeeCubit(
        repository,
        newRequestId: () => 'req-${++ids}',
      );
      addTearDown(cubit.close);
      await cubit.load();
      repository.failure = AdminFailure.outcomeUnknown;

      await cubit.submit(draft());
      expect(
        (cubit.state as AddEmployeeReady).failure,
        AdminFailure.outcomeUnknown,
      );
      repository.failure = null;
      await cubit.submit(draft());
      expect(cubit.state, isA<AddEmployeeCreated>());
      expect(repository.created.map((c) => c.$2), ['req-1', 'req-1']);
    });

    test('changed details get a new request id', () async {
      final repository = FakeAdminRepository();
      var ids = 0;
      final cubit = AddEmployeeCubit(
        repository,
        newRequestId: () => 'req-${++ids}',
      );
      addTearDown(cubit.close);
      await cubit.load();
      repository.failure = AdminFailure.accountConflict;
      await cubit.submit(draft());
      await cubit.submit(draft(username: 'sara.kamal'));
      expect(repository.created.map((c) => c.$2), ['req-1', 'req-2']);
    });

    test('invalid fields are shown and nothing is sent', () async {
      final repository = FakeAdminRepository();
      final cubit = AddEmployeeCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.submit(draft(username: '!'));
      expect((cubit.state as AddEmployeeReady).invalidFields, {
        NewEmployeeField.username,
      });
      expect(repository.created, isEmpty);
    });

    test('a double tap sends once', () async {
      final repository = FakeAdminRepository()..gate = Completer();
      final cubit = AddEmployeeCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      final first = cubit.submit(draft());
      await cubit.submit(draft());
      repository.gate!.complete();
      await first;
      expect(repository.created, hasLength(1));
    });
  });

  group('AdminDashboardCubit', () {
    test('a failed refresh keeps the rows, marked stale', () async {
      final repository = FakeAdminRepository()
        ..employees = [employee(monaId, 'Mona Ali')];
      final cubit = AdminDashboardCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      expect((cubit.state as AdminDashboardLoaded).stale, isFalse);

      repository.failure = AdminFailure.network;
      await cubit.load();
      final state = cubit.state as AdminDashboardLoaded;
      expect(state.stale, isTrue);
      expect(state.rows, hasLength(1));
    });

    test('a failed first load is an error', () async {
      final cubit = AdminDashboardCubit(
        FakeAdminRepository()..failure = AdminFailure.notAllowed,
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state, isA<AdminDashboardError>());
    });
  });

  group('AdminRequestsCubit', () {
    test('a reviewed request leaves the list; a double tap is busy', () async {
      final repository = FakeAdminRepository()
        ..requests = [cashRequest()]
        ..gate = Completer();
      final cubit = AdminRequestsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      final first = cubit.review(cashRequest(), approve: true, note: 'ok');
      expect(
        await cubit.review(cashRequest(), approve: true),
        AdminFailure.busy,
      );
      repository.gate!.complete();
      expect(await first, isNull);
      expect((cubit.state as AdminRequestsLoaded).requests, isEmpty);
      expect(repository.reviews.single, ('cash-1', true, 'ok'));
    });
  });

  group('LocaleCubit', () {
    test('Arabic by default; a choice is saved and restored', () async {
      final store = MemoryLocaleStore();
      final cubit = LocaleCubit(store);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state, const Locale('ar'));

      await cubit.select(const Locale('en'));
      expect(store.saved, 'en');

      final restarted = LocaleCubit(store);
      addTearDown(restarted.close);
      await restarted.load();
      expect(restarted.state, const Locale('en'));
    });

    test('ignores an unknown saved value', () async {
      final cubit = LocaleCubit(MemoryLocaleStore('fr'));
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state, const Locale('ar'));
    });
  });

  group('Pages', () {
    Future<void> show(
      WidgetTester tester,
      Widget page, {
      required FakeAdminRepository admin,
      UserEntity? user,
      DateTime? now,
    }) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const SizedBox());
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => page),
          GoRoute(
            path: '/admin/:rest',
            builder: (_, state) => Scaffold(body: Text(state.uri.path)),
          ),
          GoRoute(
            path: '/admin/employees/:id',
            builder: (_, state) => Scaffold(body: Text(state.uri.path)),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        withAppProviders(
          BlocProvider(
            create: (_) => ClockCubit(now: () => now ?? midday),
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
          admin: admin,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('dashboard: counts, search and a forgotten check-out', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..employees = [
          employee(monaId, 'Mona Ali'),
          employee('22222222-2222-4222-8222-222222222222', 'Omar Hassan'),
          employee(adminId, 'Test Admin', active: false),
        ]
        ..today = {monaId: sessionOf(recordRow(monaId))};
      await show(
        tester,
        const AdminDashboardView(),
        admin: admin,
        now: evening,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Still checked in after the shift end'), findsOneWidget);
      expect(find.textContaining('Inactive'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('adminSearch')), 'omar');
      await tester.pumpAndSettle();
      expect(find.text('Mona Ali'), findsNothing);
      expect(find.text('Omar Hassan'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('adminSearch')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No employees found'), findsOneWidget);
    });

    testWidgets(
      'dashboard: before the shift ends a session is just in progress',
      (tester) async {
        final admin = FakeAdminRepository()
          ..employees = [employee(monaId, 'Mona Ali')]
          ..today = {monaId: sessionOf(recordRow(monaId))};
        await show(tester, const AdminDashboardView(), admin: admin);
        expect(find.text('In progress'), findsOneWidget);
        expect(find.text('Still checked in after the shift end'), findsNothing);
      },
    );

    testWidgets('add employee: field errors, then the account is created', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..schedules = [
          const WorkScheduleOption(
            id: scheduleId,
            name: 'Standard',
            timezone: 'Africa/Cairo',
          ),
        ];
      await show(tester, const AddEmployeeView(), admin: admin);
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(admin.created, isEmpty);

      await tester.enterText(find.byKey(const Key('fullName')), 'Sara Kamal');
      await tester.enterText(find.byKey(const Key('username')), 'sara.k');
      await tester.enterText(
        find.byKey(const Key('email')),
        'sara@example.com',
      );
      await tester.enterText(find.byKey(const Key('employeeCode')), 'EMP-9');
      await tester.enterText(
        find.byKey(const Key('password')),
        'a-long-first-password',
      );
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(admin.created.single.$1, draft());
      expect(
        find.textContaining('Account created for Sara Kamal'),
        findsOneWidget,
      );
    });

    testWidgets('requests: approve a cash request', (tester) async {
      final admin = FakeAdminRepository()..requests = [cashRequest()];
      await show(tester, const AdminRequestsView(), admin: admin);
      expect(find.text('Mona Ali · EMP-11'), findsOneWidget);
      expect(find.text('250.5 EGP'), findsOneWidget);

      await tester.tap(find.byKey(const Key('approve-cash-1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('reviewNote')), 'OK');
      await tester.tap(find.byKey(const Key('confirmReview')));
      await tester.pumpAndSettle();
      expect(admin.reviews.single, ('cash-1', true, 'OK'));
      expect(find.text('Request approved.'), findsOneWidget);
      expect(find.text('No pending requests'), findsOneWidget);
    });

    testWidgets('profile: switching the language keeps the session', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = MemoryLocaleStore();
      await tester.pumpWidget(
        withAppProviders(
          BlocProvider(
            create: (_) => LocaleCubit(store),
            child: BlocBuilder<LocaleCubit, Locale>(
              builder: (context, locale) => MaterialApp(
                theme: AppTheme.light,
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Scaffold(body: ProfileViewBody()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ملفك الشخصي'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Test Employee'), findsOneWidget);
      expect(store.saved, 'en');
    });
  });
}
