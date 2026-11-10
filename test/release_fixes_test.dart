import 'package:efs_work_tracker/app/features/admin/data/repositories/supabase_admin_repository.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/employee_entity.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/manager/admin_dashboard_cubit/admin_dashboard_cubit.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/add_employee_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/attendance_session_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/shift_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/attendance_session_card.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/home_view_body.dart';
import 'package:efs_work_tracker/core/constants/constants.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/core/router/app_router.dart';
import 'package:efs_work_tracker/core/router/app_routes.dart';
import 'package:efs_work_tracker/core/services/database_services.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/core/theme/app_theme_colors.dart';
import 'package:efs_work_tracker/core/widgets/feedback/app_dialog.dart';
import 'package:efs_work_tracker/core/widgets/feedback/app_message_type.dart';
import 'package:efs_work_tracker/core/widgets/feedback/app_snack_bar.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_providers.dart';
import 'helpers/fake_admin_repository.dart';
import 'helpers/fake_evidence_storage.dart';
import 'helpers/fake_auth_repository.dart';

// Sunday 1 November 2026. Cairo is UTC+2 (summer time ended 29 October).
const monaId = '11111111-1111-4111-8111-111111111111';
const scheduleId = '44444444-4444-4444-8444-444444444444';

/// An `attendance_records` row as the server saves it: the shift instants
/// come from the employee's schedule at check-in.
AttendanceSessionEntity day({
  String id = 'record-1',
  required DateTime start,
  required DateTime end,
  required DateTime checkIn,
  DateTime? checkOut,
  bool autoClosed = false,
}) {
  final json = <String, dynamic>{
    'id': id,
    'work_date': '2026-11-01',
    'timezone': 'Africa/Cairo',
    'scheduled_start': start.toIso8601String(),
    'scheduled_end': end.toIso8601String(),
    'grace_minutes': 15,
    'actual_checkin': checkIn.toIso8601String(),
    'actual_checkout': checkOut?.toIso8601String(),
    'auto_closed': autoClosed,
    'auto_closed_at': autoClosed
        ? DateTime.utc(2026, 11, 1, 22).toIso8601String()
        : null,
    'auto_close_policy': 'midnight',
    'auto_close_deadline': DateTime.utc(2026, 11, 1, 22).toIso8601String(),
    'effective_checkin': null,
    'effective_checkout': null,
    'has_correction': false,
    'late_minutes': 0,
    'attendance_events': <Map<String, dynamic>>[],
  };
  return AttendanceSessionModel.fromJson(
    json,
    shift: ShiftModel.fromRecord(json),
  );
}

// 08:00–16:00 and 14:00–22:00 in Cairo.
final morningStart = DateTime.utc(2026, 11, 1, 6);
final morningEnd = DateTime.utc(2026, 11, 1, 14);
final eveningStart = DateTime.utc(2026, 11, 1, 12);
final eveningEnd = DateTime.utc(2026, 11, 1, 20);

AttendanceSessionEntity morning({
  DateTime? checkOut,
  bool autoClosed = false,
}) => day(
  start: morningStart,
  end: morningEnd,
  checkIn: DateTime.utc(2026, 11, 1, 6, 5),
  checkOut: checkOut,
  autoClosed: autoClosed,
);

EmployeeEntity employee(String id, String name, {UserRole? role}) =>
    EmployeeEntity(
      id: id,
      fullName: name,
      username: name.toLowerCase().replaceAll(' ', '.'),
      employeeCode: 'EMP-1',
      role: role ?? UserRole.employee,
      isActive: true,
      mustChangePassword: false,
      scheduleId: scheduleId,
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

Widget app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  group('Early departure: the employee\'s own shift end', () {
    test('a check-out before the shift end is an early departure', () {
      final left = morning(checkOut: DateTime.utc(2026, 11, 1, 12, 30));
      expect(left.leftEarly, isTrue);
      expect(left.leftEarlyBy, const Duration(hours: 1, minutes: 30));
      // Its hours are still confirmed: it is not a missing check-out.
      expect(left.isVerified, isTrue);
      expect(left.needsReview, isFalse);
    });

    test('at or after the shift end is not flagged', () {
      expect(morning(checkOut: morningEnd).leftEarly, isFalse);
      expect(
        morning(checkOut: DateTime.utc(2026, 11, 1, 15)).leftEarly,
        isFalse,
      );
    });

    test('a missing check-out is not an early departure', () {
      expect(morning().leftEarly, isFalse, reason: 'still working');
      final closed = morning(autoClosed: true);
      expect(closed.leftEarly, isFalse);
      expect(closed.needsReview, isTrue);
    });

    test('an evening shift is judged by its own end, not a global 4 PM', () {
      AttendanceSessionEntity evening(DateTime out) => day(
        start: eveningStart,
        end: eveningEnd,
        checkIn: DateTime.utc(2026, 11, 1, 12, 2),
        checkOut: out,
      );
      // 17:00 Cairo is after a morning shift's end, but early for 14–22.
      expect(evening(DateTime.utc(2026, 11, 1, 15)).leftEarly, isTrue);
      expect(evening(eveningEnd).leftEarly, isFalse);
    });
  });

  group('Admin dashboard', () {
    test('lists recent early departures with their employee', () async {
      final repository = FakeAdminRepository()
        ..employees = [employee(monaId, 'Mona Ali')]
        ..recent = [
          (
            employeeId: monaId,
            session: morning(checkOut: DateTime.utc(2026, 11, 1, 12, 30)),
          ),
          (employeeId: monaId, session: morning(checkOut: morningEnd)),
          (employeeId: 'unknown', session: morning(checkOut: morningStart)),
        ];
      final cubit = AdminDashboardCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      final state = cubit.state as AdminDashboardLoaded;
      expect(state.earlyDepartures, hasLength(1));
      expect(state.earlyDepartures.single.employee.fullName, 'Mona Ali');
    });

    testWidgets('shows who left early, the date, shift and times', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final early = morning(checkOut: DateTime.utc(2026, 11, 1, 12, 30));
      final admin = FakeAdminRepository()
        ..employees = [employee(monaId, 'Mona Ali')]
        ..today = {monaId: early}
        ..recent = [(employeeId: monaId, session: early)];
      await tester.pumpWidget(
        withAppProviders(
          BlocProvider(
            create: (_) => ClockCubit(now: () => DateTime.utc(2026, 11, 1, 15)),
            child: app(const AdminDashboardView()),
          ),
          admin: admin,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Early departures to review'), findsOneWidget);
      final tile = find.byKey(const Key('earlyDeparture-record-1'));
      expect(tile, findsOneWidget);
      // intl puts a narrow no-break space before AM/PM.
      Finder inTile(String text) => find.descendant(
        of: tile,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.data?.replaceAll(' ', ' ').replaceAll(' ', ' ') == text,
        ),
      );
      expect(inTile('Mona Ali'), findsOneWidget);
      expect(inTile('Sunday, November 1, 2026'), findsOneWidget);
      expect(inTile('8:00 AM – 4:00 PM'), findsOneWidget, reason: 'shift');
      expect(inTile('2:30 PM'), findsOneWidget, reason: 'actual check-out');
      expect(inTile('4:00 PM'), findsOneWidget, reason: 'shift end');
      expect(inTile('1h 30m early'), findsOneWidget);
      // Today's row is flagged too.
      expect(find.text('Left early'), findsWidgets);
    });
  });

  group('Home card status pill', () {
    Future<Color?> badgeColor(WidgetTester tester, DateTime now) async {
      await tester.pumpWidget(
        withAppProviders(
          app(
            Scaffold(
              body: SingleChildScrollView(
                child: AttendanceSessionCard(
                  session: now.isBefore(morningEnd)
                      ? morning()
                      : morning(checkOut: morningEnd),
                  now: now,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final badge = find.byKey(const Key('attendanceStatusBadge'));
      final box = tester.widget<Container>(
        find.descendant(of: badge, matching: find.byType(Container)).first,
      );
      return (box.decoration as BoxDecoration?)?.color;
    }

    testWidgets('is green while checked in, neutral after check-out', (
      tester,
    ) async {
      final theme = AppTheme.light;
      expect(
        await badgeColor(tester, DateTime.utc(2026, 11, 1, 9)),
        theme.colorScheme.primary,
      );
      expect(
        await badgeColor(tester, DateTime.utc(2026, 11, 1, 15)),
        theme.extension<AppThemeColors>()!.brandSurfaceBadge,
      );
    });
  });

  group('Cash requests are for employees only', () {
    Future<void> showHome(WidgetTester tester, UserEntity user) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        withAppProviders(app(const Scaffold(body: HomeViewBody())), user: user),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the Home entry is hidden from admins', (tester) async {
      await showHome(tester, testUser());
      expect(find.text('Need a cash advance?'), findsOneWidget);

      await showHome(tester, adminUser());
      expect(find.text('Need a cash advance?'), findsNothing);
    });

    test('the cash routes send admins home', () {
      final admin = AuthSignedIn(adminUser());
      final worker = AuthSignedIn(testUser());
      for (final route in [AppRoutes.cashRequest, AppRoutes.newCashRequest]) {
        expect(AppRouter.redirectFor(admin, route), AppRoutes.home);
        expect(AppRouter.redirectFor(worker, route), isNull);
      }
      expect(
        AppRouter.redirectFor(worker, AppRoutes.adminDashboard),
        AppRoutes.home,
      );
      expect(AppRouter.redirectFor(admin, AppRoutes.adminDashboard), isNull);
    });
  });

  group('Dialogs and SnackBars', () {
    testWidgets('one SnackBar at a time, with the type\'s icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  showAppSnackBar(messenger, 'First');
                  showAppSnackBar(
                    messenger,
                    'تم حفظ الطلب بنجاح، وسيتم إشعارك عند مراجعته من قبل المسؤول.',
                    type: AppMessageType.success,
                  );
                },
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('appSnackBar')), findsOneWidget);
      expect(find.text('First'), findsNothing);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'long Arabic wraps');
    });

    testWidgets('confirmation dialog answers true or false', (tester) async {
      bool? answer;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => answer = await showAppConfirmationDialog(
                context,
                title: 'Reject?',
                message: 'Sure?',
                confirmLabel: 'Reject',
                cancelLabel: 'Cancel',
                destructive: true,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmDialog')));
      await tester.pumpAndSettle();
      expect(answer, isTrue);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(answer, isFalse);
    });
  });

  group(
    'Role on account creation (prepared, off until the backend allows)',
    () {
      NewEmployeeDraft draft({UserRole role = UserRole.employee}) =>
          NewEmployeeDraft(
            fullName: 'Sara Kamal',
            username: 'sara.k',
            email: 'sara@example.com',
            employeeCode: 'EMP-9',
            scheduleId: scheduleId,
            password: 'a-long-first-password',
            role: role,
          );

      test('employee is the default', () {
        expect(draft().role, UserRole.employee);
        expect(draft(), isNot(draft(role: UserRole.admin)));
      });

      test('the role is only sent once the backend accepts it', () async {
        final bodies = <Map<String, dynamic>>[];
        Future<Object?> accounts(Map<String, dynamic> body) async {
          bodies.add(body);
          return {'id': 'new'};
        }

        SupabaseAdminRepository repository({required bool sendsRole}) =>
            SupabaseAdminRepository(
              storageServices: FakeEvidenceStorage(),
              databaseServices: _NoDatabase(),
              accountsFunction: accounts,
              currentUserId: () => 'admin-1',
              sendsRole: sendsRole,
            );

        await repository(sendsRole: false)
            .createEmployee(draft(role: UserRole.admin), requestId: 'r1');
        expect(bodies.last.containsKey('role'), isFalse);

        await repository(sendsRole: true)
            .createEmployee(draft(role: UserRole.admin), requestId: 'r2');
        expect(bodies.last['role'], 'admin');
      });

      testWidgets('the selector creates an admin when chosen', (tester) async {
        tester.view.physicalSize = const Size(430, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final admin = FakeAdminRepository()
          ..schedules = [
            const WorkScheduleOption(
              id: scheduleId,
              name: 'Default',
              timezone: 'Africa/Cairo',
            ),
          ];
        await tester.pumpWidget(
          withAppProviders(
            app(const AddEmployeeView(showRoleSelector: true)),
            admin: admin,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('roleSelector')), findsOneWidget);
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
        await tester.tap(find.text('Administrator'));
        await tester.pump();
        await tester.ensureVisible(find.text('Create account'));
        await tester.tap(find.text('Create account'));
        await tester.pumpAndSettle();
        expect(admin.created.single.$1.role, UserRole.admin);
      });

      testWidgets('the role selector and phone are shown by default', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(430, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          withAppProviders(
            app(const AddEmployeeView()),
            admin: FakeAdminRepository(),
          ),
        );
        await tester.pumpAndSettle();
        expect(Constants.accountRoleAndPhone, isTrue);
        expect(find.byKey(const Key('roleSelector')), findsOneWidget);
        expect(find.byKey(const Key('phone')), findsOneWidget);
        // Employee is preselected.
        final selector = tester.widget<SegmentedButton<UserRole>>(
          find.byKey(const Key('roleSelector')),
        );
        expect(selector.selected, {UserRole.employee});
      });

      testWidgets('switched off, neither is shown', (tester) async {
        await tester.pumpWidget(
          withAppProviders(
            app(const AddEmployeeView(showRoleSelector: false)),
            admin: FakeAdminRepository(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('roleSelector')), findsNothing);
        expect(find.byKey(const Key('phone')), findsNothing);
      });
    },
  );
}

class _NoDatabase implements DatabaseServices {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
