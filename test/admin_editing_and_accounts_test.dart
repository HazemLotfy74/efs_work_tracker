import 'dart:async';

import 'package:efs_work_tracker/app/features/admin/data/repositories/supabase_admin_repository.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/employee_entity.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/manager/edit_attendance_cubit/edit_attendance_cubit.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_attendance_day_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/edit_attendance_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/employee_details_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/attendance_session_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/shift_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/views/login_view.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/widgets/change_password_view_body.dart';
import 'package:efs_work_tracker/core/constants/constants.dart';
import 'package:efs_work_tracker/core/errors/admin_errors.dart';
import 'package:efs_work_tracker/core/errors/failure.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/core/services/database_services.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/core/widgets/pickers/app_pickers.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:efs_work_tracker/core/router/app_router.dart';
import 'package:efs_work_tracker/core/router/app_routes.dart';

import 'helpers/app_providers.dart';
import 'helpers/fake_admin_repository.dart';
import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_evidence_storage.dart';

// Sunday 1 November 2026, Cairo UTC+2; shift 08:00–16:00 = 06:00–14:00 UTC.
const monaId = '11111111-1111-4111-8111-111111111111';
const scheduleA = '44444444-4444-4444-8444-444444444444';
final shiftStart = DateTime.utc(2026, 11, 1, 6);
final shiftEnd = DateTime.utc(2026, 11, 1, 14);
final evening = DateTime.utc(2026, 11, 1, 18);

/// Checked in 08:30, checked out 16:30 (Cairo).
AttendanceSessionEntity day({bool open = false, bool corrected = false}) {
  final json = <String, dynamic>{
    'id': 'day-1',
    'work_date': '2026-11-01',
    'timezone': 'Africa/Cairo',
    'scheduled_start': shiftStart.toIso8601String(),
    'scheduled_end': shiftEnd.toIso8601String(),
    'grace_minutes': 15,
    'actual_checkin': DateTime.utc(2026, 11, 1, 6, 30).toIso8601String(),
    'actual_checkout': open
        ? null
        : DateTime.utc(2026, 11, 1, 14, 30).toIso8601String(),
    'auto_closed': false,
    'auto_closed_at': null,
    'auto_close_policy': 'midnight',
    'auto_close_deadline': DateTime.utc(2026, 11, 1, 22).toIso8601String(),
    'effective_checkin': corrected
        ? DateTime.utc(2026, 11, 1, 6).toIso8601String()
        : null,
    'effective_checkout': corrected
        ? DateTime.utc(2026, 11, 1, 14, 30).toIso8601String()
        : null,
    'has_correction': corrected,
    'late_minutes': 15,
    'attendance_events': <Map<String, dynamic>>[],
  };
  return AttendanceSessionModel.fromJson(
    json,
    shift: ShiftModel.fromRecord(json),
  );
}

EmployeeEntity mona({String? phone}) => EmployeeEntity(
  id: monaId,
  fullName: 'Mona Ali',
  username: 'mona.ali',
  employeeCode: 'EMP-11',
  role: UserRole.employee,
  isActive: true,
  mustChangePassword: false,
  scheduleId: scheduleA,
  phone: phone,
);

UserEntity adminUser() => const UserEntity(
  uID: 'admin-1',
  email: 'admin@example.com',
  fullName: 'Test Admin',
  username: 'test.admin',
  employeeCode: 'ADM-1',
  role: UserRole.admin,
  isActive: true,
  mustChangePassword: false,
);

FakeAdminRepository repositoryWith(AttendanceSessionEntity session) =>
    FakeAdminRepository()
      ..employees = [mona()]
      ..days = {'day-1': (employeeId: monaId, session: session)};

Widget app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Future<void> show(
  WidgetTester tester,
  Widget page,
  FakeAdminRepository admin, {
  UserEntity? user,
}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    withAppProviders(
      BlocProvider(
        create: (_) => ClockCubit(now: () => evening),
        child: app(page),
      ),
      admin: admin,
      user: user ?? adminUser(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Admin attendance correction: rules before sending', () {
    test('valid times are sent once; recorded times are not touched', () async {
      final admin = repositoryWith(day());
      final cubit = EditAttendanceCubit(admin, 'day-1');
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.save(
        checkIn: DateTime.utc(2026, 11, 1, 6),
        checkOut: DateTime.utc(2026, 11, 1, 14, 30),
        reason: 'Arrived at 8, forgot to check in',
      );
      expect(cubit.state, isA<EditAttendanceSaved>());
      final sent = admin.corrected.single;
      expect(sent.$1, 'day-1');
      expect(sent.$2, DateTime.utc(2026, 11, 1, 6));
      expect(sent.$3, DateTime.utc(2026, 11, 1, 14, 30));
    });

    test('check-out before check-in, outside the day, or no reason', () async {
      final admin = repositoryWith(day());
      final cubit = EditAttendanceCubit(admin, 'day-1');
      addTearDown(cubit.close);
      await cubit.load();
      AdminFailure? failure() => (cubit.state as EditAttendanceReady).failure;

      await cubit.save(
        checkIn: DateTime.utc(2026, 11, 1, 10),
        checkOut: DateTime.utc(2026, 11, 1, 9),
        reason: 'x',
      );
      expect(failure(), AdminFailure.invalidTimes);
      await cubit.save(
        checkIn: DateTime.utc(2026, 10, 31, 6),
        checkOut: DateTime.utc(2026, 11, 1, 9),
        reason: 'x',
      );
      expect(failure(), AdminFailure.invalidTimes, reason: 'other date');
      await cubit.save(
        checkIn: DateTime.utc(2026, 11, 1, 6),
        checkOut: DateTime.utc(2026, 11, 1, 22),
        reason: 'x',
      );
      expect(failure(), AdminFailure.invalidTimes, reason: 'at midnight');
      await cubit.save(
        checkIn: DateTime.utc(2026, 11, 1, 6),
        checkOut: null,
        reason: 'x',
      );
      expect(failure(), AdminFailure.invalidTimes, reason: 'missing time');
      await cubit.save(
        checkIn: DateTime.utc(2026, 11, 1, 6),
        checkOut: DateTime.utc(2026, 11, 1, 9),
        reason: '   ',
      );
      expect(failure(), AdminFailure.invalidReason);
      expect(admin.corrected, isEmpty, reason: 'nothing invalid is sent');
    });

    test('an open day cannot be corrected', () async {
      final admin = repositoryWith(day(open: true));
      final cubit = EditAttendanceCubit(admin, 'day-1');
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.save(
        checkIn: DateTime.utc(2026, 11, 1, 6),
        checkOut: DateTime.utc(2026, 11, 1, 9),
        reason: 'x',
      );
      expect(
        (cubit.state as EditAttendanceReady).failure,
        AdminFailure.notClosed,
      );
    });

    test('the server\'s refusal is shown and nothing is saved', () async {
      final admin = repositoryWith(day());
      final cubit = EditAttendanceCubit(admin, 'day-1');
      addTearDown(cubit.close);
      await cubit.load();
      admin.failure = AdminFailure.notAllowed;
      await cubit.save(
        checkIn: DateTime.utc(2026, 11, 1, 6),
        checkOut: DateTime.utc(2026, 11, 1, 14),
        reason: 'x',
      );
      final state = cubit.state as EditAttendanceReady;
      expect(state.failure, AdminFailure.notAllowed);
      expect(state.saving, isFalse);
    });

    test('a double tap sends once', () async {
      final admin = repositoryWith(day())..gate = Completer();
      final cubit = EditAttendanceCubit(admin, 'day-1');
      addTearDown(cubit.close);
      await cubit.load();
      Future<void> save() => cubit.save(
        checkIn: DateTime.utc(2026, 11, 1, 6),
        checkOut: DateTime.utc(2026, 11, 1, 14),
        reason: 'x',
      );
      final first = save();
      await save();
      admin.gate!.complete();
      await first;
      expect(admin.corrected, hasLength(1));
    });

    test('corrected times drive hours and overtime everywhere', () {
      // Recorded 08:30–16:30 (8h); corrected to 08:00–16:30 (8h30m).
      final corrected = day(corrected: true);
      expect(
        corrected.verifiedDuration!.worked,
        const Duration(hours: 8, minutes: 30),
      );
      expect(corrected.verifiedDuration!.overtime, const Duration(minutes: 30));
      // The recorded check-in stays as the evidence.
      expect(corrected.checkInTime, DateTime.utc(2026, 11, 1, 6, 30));
    });
  });

  group('admin_correct_attendance call', () {
    test('sends UTC times and a trimmed reason; maps refusals', () async {
      final db = _Rpc();
      final repository = SupabaseAdminRepository(
        storageServices: FakeEvidenceStorage(),
        databaseServices: db,
        accountsFunction: (_) async => null,
        currentUserId: () => 'admin-1',
      );
      await repository.correctAttendance(
        'day-1',
        checkIn: DateTime.utc(2026, 11, 1, 6),
        checkOut: DateTime.utc(2026, 11, 1, 14),
        reason: '  Forgot to check in  ',
      );
      expect(db.calls.single.$1, 'admin_correct_attendance');
      expect(db.calls.single.$2, {
        'p_attendance_id': 'day-1',
        'p_checkin': '2026-11-01T06:00:00.000Z',
        'p_checkout': '2026-11-01T14:00:00.000Z',
        'p_reason': 'Forgot to check in',
      });

      AdminFailure map(String code, String message) =>
          SupabaseAdminRepository.failureFor(code, message);
      expect(
        map('42501', 'You cannot correct your own attendance'),
        AdminFailure.ownAttendance,
      );
      expect(
        map(
          '42501',
          'An active, password-ready authorized account is required',
        ),
        AdminFailure.notAllowed,
        reason: 'an employee calling it directly',
      );
      expect(
        map(
          '22023',
          'Proposed correction times are outside the allowed attendance period',
        ),
        AdminFailure.invalidTimes,
      );
      expect(
        map('23505', 'A pending correction already exists for this attendance'),
        AdminFailure.pendingCorrection,
      );
      expect(map('22023', 'No change was requested'), AdminFailure.noChange);
      expect(
        map('22023', 'Attendance must be closed before correction'),
        AdminFailure.notClosed,
      );
      expect(
        map('PGRST202', 'Could not find the function'),
        AdminFailure.serviceUnavailable,
        reason: 'migration not applied yet',
      );
    });
  });

  group('Edit times pages', () {
    testWidgets('the day page offers Edit times only when allowed', (
      tester,
    ) async {
      await show(
        tester,
        const AdminAttendanceDayView(
          attendanceId: 'day-1',
          showMaps: false,
          showEditAction: true,
        ),
        repositoryWith(day()),
      );
      expect(find.byKey(const Key('editTimes')), findsOneWidget);

      // Not on an open day.
      await show(
        tester,
        const AdminAttendanceDayView(
          attendanceId: 'day-1',
          showMaps: false,
          showEditAction: true,
        ),
        repositoryWith(day(open: true)),
      );
      expect(find.byKey(const Key('editTimes')), findsNothing);

      // On by default now that admin_correct_attendance is live.
      expect(Constants.adminAttendanceCorrection, isTrue);
      await show(
        tester,
        const AdminAttendanceDayView(attendanceId: 'day-1', showMaps: false),
        repositoryWith(day()),
      );
      expect(find.byKey(const Key('editTimes')), findsOneWidget);

      // Never on the admin's own day (the database refuses it too).
      final own = FakeAdminRepository()
        ..employees = [mona()]
        ..days = {'day-1': (employeeId: 'admin-1', session: day())};
      await show(
        tester,
        const AdminAttendanceDayView(attendanceId: 'day-1', showMaps: false),
        own,
      );
      expect(find.byKey(const Key('editTimes')), findsNothing);
    });

    testWidgets('Edit times opens the editor from the day page', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/day',
        routes: [
          GoRoute(
            path: '/day',
            builder: (_, _) => const AdminAttendanceDayView(
              attendanceId: 'day-1',
              showMaps: false,
            ),
          ),
          GoRoute(
            path: '/admin/attendance/:id/edit',
            builder: (_, state) =>
                EditAttendanceView(attendanceId: state.pathParameters['id']!),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        withAppProviders(
          BlocProvider(
            create: (_) => ClockCubit(now: () => evening),
            child: MaterialApp.router(
              theme: AppTheme.light,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
          admin: repositoryWith(day()),
          user: adminUser(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editTimes')));
      await tester.pumpAndSettle();
      expect(find.byType(EditAttendanceView), findsOneWidget);
      expect(find.byKey(const Key('saveTimes')), findsOneWidget);
    });

    testWidgets('edit, confirm with old → new, save', (tester) async {
      final admin = repositoryWith(day());
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      bool? saved;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    saved = await context.push<bool>('/edit'),
                child: const Text('Open editor'),
              ),
            ),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, _) => const EditAttendanceView(attendanceId: 'day-1'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        withAppProviders(
          MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
          admin: admin,
          user: adminUser(),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Recorded by the app'), findsOneWidget);
      // The pickers start at the recorded times (company time).
      expect(find.text('8:30 AM'), findsWidgets);

      // Change check-in to 8:00 with the themed time picker.
      await tester.tap(find.byKey(const Key('editCheckIn')));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), '8');
      await tester.enterText(fields.at(1), '00');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('editReason')),
        'Arrived at 8, forgot to check in',
      );
      await tester.ensureVisible(find.byKey(const Key('saveTimes')));
      await tester.tap(find.byKey(const Key('saveTimes')));
      await tester.pumpAndSettle();
      expect(find.text('Save the corrected times?'), findsOneWidget);
      // intl puts a narrow no-break space before AM/PM.
      bool says(Widget w, String text) =>
          w is Text && (w.data ?? '').replaceAll(' ', ' ').contains(text);
      expect(
        find.byWidgetPredicate((w) => says(w, '8:30 AM → 8:00 AM')),
        findsOneWidget,
      );
      expect(find.textContaining('Overtime: 30m'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmDialog')));
      await tester.pumpAndSettle();
      expect(admin.corrected.single.$2, DateTime.utc(2026, 11, 1, 6));
      // Back on the day page, told that it was saved.
      expect(saved, isTrue);
      expect(find.text('Attendance times updated.'), findsOneWidget);
    });

    testWidgets('an invalid edit shows why and sends nothing', (tester) async {
      final admin = repositoryWith(day());
      await show(
        tester,
        const EditAttendanceView(attendanceId: 'day-1'),
        admin,
      );
      await tester.ensureVisible(find.byKey(const Key('saveTimes')));
      await tester.tap(find.byKey(const Key('saveTimes')));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a reason of up to 2000 characters.'),
        findsOneWidget,
      );
      expect(admin.corrected, isEmpty);
    });
  });

  group('Accounts: role and optional phone', () {
    NewEmployeeDraft draft({
      String phone = '',
      UserRole role = UserRole.employee,
    }) => NewEmployeeDraft(
      fullName: 'Sara Kamal',
      username: 'sara.k',
      email: 'sara@example.com',
      employeeCode: 'EMP-9',
      scheduleId: scheduleA,
      password: 'a-long-first-password',
      role: role,
      phone: phone,
    );

    test('phone is optional and validated only when given', () {
      expect(draft().phone, isNull);
      expect(draft().invalidFields, isEmpty);
      expect(draft(phone: '+20 101 234-5678').phone, '+201012345678');
      expect(draft(phone: '+20 101 234-5678').invalidFields, isEmpty);
      expect(draft(phone: '01012345678').invalidFields, {
        NewEmployeeField.phone,
      });
      expect(draft(phone: '+0123').invalidFields, {NewEmployeeField.phone});
    });

    test(
      'role and phone are sent only once the backend accepts them',
      () async {
        final bodies = <Map<String, dynamic>>[];
        Future<Object?> accounts(Map<String, dynamic> body) async {
          bodies.add(body);
          return {'id': 'new'};
        }

        SupabaseAdminRepository repository(bool enabled) =>
            SupabaseAdminRepository(
              storageServices: FakeEvidenceStorage(),
              databaseServices: _Rpc(),
              accountsFunction: accounts,
              currentUserId: () => 'admin-1',
              sendsRole: enabled,
            );

        await repository(false).createEmployee(
          draft(phone: '+201012345678', role: UserRole.admin),
          requestId: 'r1',
        );
        expect(bodies.last.keys, isNot(contains('phone')));
        expect(bodies.last.keys, isNot(contains('role')));

        await repository(true).createEmployee(
          draft(phone: '+201012345678', role: UserRole.admin),
          requestId: 'r2',
        );
        expect(bodies.last['role'], 'admin');
        expect(bodies.last['phone'], '+201012345678');

        await repository(true).createEmployee(draft(), requestId: 'r3');
        expect(bodies.last['role'], 'employee');
        expect(bodies.last.keys, isNot(contains('phone')), reason: 'empty');
      },
    );

    testWidgets('the employee page shows the phone when there is one', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..employees = [mona(phone: '+201012345678')];
      await show(tester, const EmployeeDetailsView(id: monaId), admin);
      expect(find.text('+201012345678'), findsOneWidget);
    });
  });

  group('Password reset', () {
    test('mobile opens the app; web returns to its own origin', () {
      expect(
        Constants.passwordResetRedirectFor(isWeb: false),
        'efsworktracker://reset-password',
      );
      // Whatever host serves the web app (dev port or production).
      expect(
        Constants.passwordResetRedirectFor(
          isWeb: true,
          page: Uri.parse('https://attendance.example.com/#/login'),
        ),
        'https://attendance.example.com/',
      );
      expect(
        Constants.passwordResetRedirectFor(
          isWeb: true,
          page: Uri.parse('http://localhost:5000/'),
        ),
        'http://localhost:5000/',
      );
    });

    test('a valid link asks for a new password, titled as a reset', () async {
      final auth = FakeAuthRepository();
      final cubit = AuthCubit(auth);
      addTearDown(cubit.close);
      await cubit.start();
      auth.openResetLink(testUser());
      await Future<void>.delayed(Duration.zero);
      final state = cubit.state as AuthPasswordChangeRequired;
      expect(state.fromResetLink, isTrue);
    });

    test('an expired or used link signs nobody in and says why', () async {
      final auth = FakeAuthRepository();
      final cubit = AuthCubit(auth);
      addTearDown(cubit.close);
      await cubit.start();
      auth.openBadResetLink();
      await Future<void>.delayed(Duration.zero);
      final state = cubit.state as AuthSignedOut;
      expect(state.linkFailure, AuthFailureReason.recoveryLinkInvalid);
    });

    test('a bad link never signs out someone who is signed in', () async {
      final auth = FakeAuthRepository(signedInUser: testUser());
      final cubit = AuthCubit(auth);
      addTearDown(cubit.close);
      await cubit.start();
      auth.openBadResetLink();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<AuthSignedIn>());
    });

    testWidgets('the sign-in screen explains a bad link', (tester) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = FakeAuthRepository();
      final cubit = AuthCubit(auth);
      addTearDown(cubit.close);
      await cubit.start();
      await tester.pumpWidget(
        BlocProvider.value(value: cubit, child: app(const LoginView())),
      );
      auth.openBadResetLink();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This reset link has expired'),
        findsOneWidget,
      );
    });

    testWidgets('the password screen says Reset after a reset link', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final auth = FakeAuthRepository();
      final cubit = AuthCubit(auth);
      addTearDown(cubit.close);
      await cubit.start();
      auth.openResetLink(testUser());
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: app(const Scaffold(body: ChangePasswordViewBody())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reset your password'), findsWidgets);
    });
  });

  group('Pickers', () {
    testWidgets(
      'date picker clamps the start day and is right to left in Arabic',
      (tester) async {
        DateTime? picked;
        await tester.pumpWidget(
          app(
            Builder(
              builder: (context) => TextButton(
                onPressed: () async => picked = await showAppDatePicker(
                  context,
                  // After the last allowed day: starts at the last day.
                  initialDate: DateTime(2030),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2026, 11, 1),
                ),
                child: const Text('Open'),
              ),
            ),
            locale: const Locale('ar'),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final dialog = find.byType(DatePickerDialog);
        expect(dialog, findsOneWidget);
        expect(Directionality.of(tester.element(dialog)), TextDirection.rtl);
        await tester.tap(find.text('حسنًا'));
        await tester.pumpAndSettle();
        expect(picked, DateTime(2026, 11, 1));
      },
    );

    test('the theme styles both pickers with the app colors', () {
      final theme = AppTheme.light;
      expect(
        theme.datePickerTheme.headerBackgroundColor,
        theme.colorScheme.primary,
      );
      expect(theme.timePickerTheme.dialHandColor, theme.colorScheme.primary);
    });

    testWidgets('the time picker follows the phone\'s 24-hour setting', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: app(
            Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppTimePicker(
                  context,
                  initialTime: const TimeOfDay(hour: 16, minute: 5),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('16'), findsWidgets);
      expect(find.text('PM'), findsNothing);
    });
  });

  test('the router keeps employees out of the edit page', () {
    final route = AppRoutes.adminEditAttendanceOf('day-1');
    expect(
      AppRouter.redirectFor(AuthSignedIn(testUser()), route),
      AppRoutes.home,
    );
    expect(AppRouter.redirectFor(AuthSignedIn(adminUser()), route), isNull);
  });
}

class _Rpc implements DatabaseServices {
  final calls = <(String, Map<String, dynamic>?)>[];

  @override
  Future<dynamic> rpc({
    required String function,
    Map<String, dynamic>? params,
  }) async {
    calls.add((function, params));
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
