import 'package:efs_work_tracker/app/features/admin/data/repositories/supabase_admin_repository.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/audit_entry_entity.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/employee_attendance_stats.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/employee_entity.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/manager/employee_details_cubit/employee_details_cubit.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/admin_attendance_day_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/audit_history_view.dart';
import 'package:efs_work_tracker/app/features/admin/presentation/views/employee_details_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/attendance_session_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/evidence_file_name.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/shift_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_type.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/core/errors/admin_errors.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/core/services/database_services.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_providers.dart';
import 'helpers/fake_admin_repository.dart';
import 'helpers/fake_evidence_storage.dart';

// Sunday 1 November 2026; Cairo is UTC+2. Shift 08:00–16:00 Cairo.
const monaId = '11111111-1111-4111-8111-111111111111';
const scheduleA = '44444444-4444-4444-8444-444444444444';
const scheduleB = '55555555-5555-4555-8555-555555555555';
final shiftStart = DateTime.utc(2026, 11, 1, 6);
final shiftEnd = DateTime.utc(2026, 11, 1, 14);
final evening = DateTime.utc(2026, 11, 1, 16);

AttendanceSessionEntity day({
  String id = 'day-1',
  String date = '2026-11-01',
  int dayOffset = 0,
  DateTime? checkOut,
  bool autoClosed = false,
  int late = 0,
  bool withEvidence = true,
  double? latitude = 30.0444,
}) {
  final offset = Duration(days: dayOffset);
  final checkIn = shiftStart.add(offset).add(const Duration(minutes: 20));
  final json = <String, dynamic>{
    'id': id,
    'work_date': date,
    'timezone': 'Africa/Cairo',
    'scheduled_start': shiftStart.add(offset).toIso8601String(),
    'scheduled_end': shiftEnd.add(offset).toIso8601String(),
    'grace_minutes': 15,
    'actual_checkin': checkIn.toIso8601String(),
    'actual_checkout': checkOut?.add(offset).toIso8601String(),
    'auto_closed': autoClosed,
    'auto_closed_at': autoClosed
        ? DateTime.utc(2026, 11, 1, 22).add(offset).toIso8601String()
        : null,
    'auto_close_policy': 'midnight',
    'auto_close_deadline': DateTime.utc(
      2026,
      11,
      1,
      22,
    ).add(offset).toIso8601String(),
    'effective_checkin': null,
    'effective_checkout': null,
    'has_correction': false,
    'late_minutes': late,
    'attendance_events': [
      if (withEvidence)
        {
          'event_type': 'check_in',
          'occurred_at': checkIn.toIso8601String(),
          'latitude': latitude,
          'longitude': 31.2357,
          'accuracy_m': 12,
          'selfie_path': '$monaId/in-$id.jpg',
        },
      if (withEvidence && checkOut != null)
        {
          'event_type': 'check_out',
          'occurred_at': checkOut.add(offset).toIso8601String(),
          'latitude': 30.05,
          'longitude': 31.24,
          'accuracy_m': 9,
          'selfie_path': '$monaId/out-$id.jpg',
        },
    ],
  };
  return AttendanceSessionModel.fromJson(
    json,
    shift: ShiftModel.fromRecord(json),
  );
}

EmployeeEntity mona({bool active = true, UserRole role = UserRole.employee}) =>
    EmployeeEntity(
      id: monaId,
      fullName: 'Mona Ali',
      username: 'mona.ali',
      employeeCode: 'EMP-11',
      role: role,
      isActive: active,
      mustChangePassword: false,
      scheduleId: scheduleA,
      createdAt: DateTime.utc(2026, 10, 20, 9),
    );

const schedules = [
  WorkScheduleOption(id: scheduleA, name: 'Morning', timezone: 'Africa/Cairo'),
  WorkScheduleOption(id: scheduleB, name: 'Evening', timezone: 'Africa/Cairo'),
];

Widget app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Future<void> show(
  WidgetTester tester,
  Widget page,
  FakeAdminRepository admin, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    withAppProviders(
      BlocProvider(
        create: (_) => ClockCubit(now: () => evening),
        child: MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
      admin: admin,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Evidence file names', () {
    const owner = (
      fullName: 'Ahmed Mohamed',
      username: 'ahmed.m',
      employeeCode: 'EMP-125',
    );

    test('identify the employee, the action and the time', () {
      final at = DateTime.utc(2026, 11, 1, 8, 5, 30);
      String name(AttendanceType type) => EvidenceFileName.descriptive(
        userId: monaId,
        owner: owner,
        type: type,
        takenAt: at,
        uniqueId: 'a81f2c0d-1111-4111-8111-111111111111',
        extension: 'jpg',
      );
      expect(
        name(AttendanceType.checkIn),
        '$monaId/Ahmed_Mohamed_EMP-125_check_in_20261101_080530_a81f2c0d.jpg',
      );
      expect(
        name(AttendanceType.checkOut),
        '$monaId/Ahmed_Mohamed_EMP-125_check_out_20261101_080530_a81f2c0d.jpg',
      );
    });

    test('the time is written in UTC whatever the device zone', () {
      final local = DateTime.utc(2026, 11, 1, 6).toLocal();
      expect(
        EvidenceFileName.descriptive(
          userId: monaId,
          owner: owner,
          type: AttendanceType.checkIn,
          takenAt: local,
          uniqueId: 'abcdef01-0000',
          extension: 'png',
        ),
        endsWith('_20261101_060000_abcdef01.png'),
      );
    });

    test('Arabic, empty or unsafe names fall back to the username', () {
      expect(EvidenceFileName.asciiName('محمد أحمد'), '');
      expect(EvidenceFileName.asciiName('  '), '');
      expect(EvidenceFileName.asciiName('Ahmed / Mohamed..'), 'Ahmed_Mohamed');
      expect(EvidenceFileName.asciiName('ahmed.m'), 'ahmed_m');
      expect(
        EvidenceFileName.asciiName('A' * 60),
        hasLength(EvidenceFileName.maxNameLength),
      );
      final path = EvidenceFileName.descriptive(
        userId: monaId,
        owner: (fullName: 'محمد أحمد', username: 'm.ahmed', employeeCode: 'E1'),
        type: AttendanceType.checkIn,
        takenAt: DateTime.utc(2026, 11, 1),
        uniqueId: '0123456789',
        extension: 'jpg',
      );
      expect(path, '$monaId/m_ahmed_E1_check_in_20261101_000000_01234567.jpg');
      // Only the user's own folder, never a nested or foreign path.
      expect(path.split('/'), hasLength(2));
      expect(path, matches(RegExp(r'^[0-9a-f-]+/[A-Za-z0-9_.-]+$')));
    });

    test('the descriptive shape matches the proposed Storage policy', () {
      // The second alternative of the proposed `attendance_selfie_upload`.
      final policy = RegExp(
        '^$monaId'
        r'/[A-Za-z0-9_-]{1,120}_check_(in|out)_[0-9]{8}_[0-9]{6}_[0-9a-f]{8}[.](jpg|jpeg|png|webp)$',
      );
      expect(
        EvidenceFileName.descriptive(
          userId: monaId,
          owner: owner,
          type: AttendanceType.checkOut,
          takenAt: DateTime.utc(2026, 11, 1, 14),
          uniqueId: 'deadbeef-0000',
          extension: 'webp',
        ),
        matches(policy),
      );
    });
  });

  group('Employee statistics', () {
    test('count from the records, confirmed hours only', () {
      final days = [
        // 08:20–17:30: 9h10m worked, 1h10m overtime, late.
        day(id: 'a', checkOut: DateTime.utc(2026, 11, 1, 15, 30), late: 5),
        // Left at 13:00, before the 16:00 end.
        day(id: 'b', dayOffset: -1, checkOut: DateTime.utc(2026, 11, 1, 11)),
        // Never checked out: closed automatically, no hours.
        day(id: 'c', dayOffset: -2, autoClosed: true),
      ];
      final stats = EmployeeAttendanceStats.of(days, evening);
      expect(stats.days, 3);
      expect(stats.worked, const Duration(hours: 13, minutes: 50));
      expect(stats.overtime, const Duration(hours: 1, minutes: 10));
      expect(stats.late, 1);
      expect(stats.leftEarly, 1);
      expect(stats.missingCheckOut, 1);
      expect(stats.needsAttention, 3);
      expect(stats.corrected, 0);
    });

    test('date ranges are inclusive work dates', () {
      final range = WorkDateRange(
        DateTime(2026, 10, 30),
        DateTime(2026, 11, 1),
      );
      expect(range.contains(DateTime(2026, 10, 30)), isTrue);
      expect(range.contains(DateTime(2026, 11, 1, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 10, 29)), isFalse);
    });
  });

  group('EmployeeDetailsCubit', () {
    FakeAdminRepository repository() => FakeAdminRepository()
      ..employees = [mona()]
      ..schedules = schedules.toList()
      ..history = {
        monaId: [
          day(id: 'today', checkOut: DateTime.utc(2026, 11, 1, 15)),
          day(
            id: 'old',
            date: '2026-10-20',
            dayOffset: -12,
            checkOut: DateTime.utc(2026, 11, 1, 15),
          ),
        ],
      };

    test('opening loads but marks nothing as reviewed', () async {
      final admin = repository();
      final cubit = EmployeeDetailsCubit(admin, monaId);
      addTearDown(cubit.close);
      await cubit.load();
      final state = cubit.state as EmployeeDetailsLoaded;
      expect(state.days, hasLength(2));
      expect(state.schedule?.name, 'Morning');
      expect(admin.activeChanges, isEmpty);
      expect(admin.scheduleChanges, isEmpty);
    });

    test('a date range filters the days', () async {
      final cubit = EmployeeDetailsCubit(repository(), monaId);
      addTearDown(cubit.close);
      await cubit.load();
      cubit.setRange(
        WorkDateRange(DateTime(2026, 11, 1), DateTime(2026, 11, 1)),
      );
      final state = cubit.state as EmployeeDetailsLoaded;
      expect(state.visibleDays.map((d) => d.id), ['today']);
      cubit.setRange(null);
      expect((cubit.state as EmployeeDetailsLoaded).visibleDays, hasLength(2));
    });

    test('deactivate and change schedule go through the admin RPCs', () async {
      final admin = repository();
      final cubit = EmployeeDetailsCubit(admin, monaId);
      addTearDown(cubit.close);
      await cubit.load();
      expect(await cubit.setActive(false), isNull);
      expect(admin.activeChanges.single, (monaId, false));
      expect((cubit.state as EmployeeDetailsLoaded).employee.isActive, isFalse);
      expect(await cubit.assignSchedule(scheduleB), isNull);
      expect(admin.scheduleChanges.single, (monaId, scheduleB));
    });

    test('a refused action is reported and the page stays', () async {
      final admin = repository();
      final cubit = EmployeeDetailsCubit(admin, monaId);
      addTearDown(cubit.close);
      await cubit.load();
      admin.failure = AdminFailure.notAllowed;
      expect(await cubit.setActive(false), AdminFailure.notAllowed);
      expect(cubit.state, isA<EmployeeDetailsLoaded>());
    });

    test('an unknown employee is not found', () async {
      final cubit = EmployeeDetailsCubit(FakeAdminRepository(), 'nobody');
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state, isA<EmployeeDetailsNotFound>());
    });
  });

  group('Admin repository: evidence and admin actions', () {
    late _RecordingDatabase db;
    late FakeEvidenceStorage storage;
    late SupabaseAdminRepository repository;

    setUp(() {
      db = _RecordingDatabase();
      storage = FakeEvidenceStorage();
      repository = SupabaseAdminRepository(
        storageServices: storage,
        databaseServices: db,
        accountsFunction: (_) async => null,
        currentUserId: () => 'admin-1',
      );
    });

    test('photos are signed for 10 minutes in the private bucket', () async {
      final url = await repository.evidenceUrl('$monaId/in-1.jpg');
      expect(url, startsWith('https://storage.test/sign/'));
      expect(storage.signed.single, (
        'attendance-evidence',
        '$monaId/in-1.jpg',
        const Duration(minutes: 10),
      ));
    });

    test('a refused signature is a failure, never a public link', () async {
      storage.signFailure = Exception('denied');
      await expectLater(
        repository.evidenceUrl('$monaId/in-1.jpg'),
        throwsA(AdminFailure.network),
      );
    });

    test('activate / schedule use the existing RPCs', () async {
      await repository.setEmployeeActive(monaId, active: false);
      await repository.assignSchedule(monaId, scheduleB);
      expect(db.rpcCalls.map((c) => c.$1), [
        'admin_set_employee_active',
        'admin_assign_schedule',
      ]);
      expect(db.rpcCalls.first.$2, {
        'p_employee_id': monaId,
        'p_is_active': false,
      });
      expect(db.rpcCalls.last.$2, {
        'p_employee_id': monaId,
        'p_schedule_id': scheduleB,
      });
    });

    test(
      'audit history merges profile and related rows, newest first',
      () async {
        db.rows['audit_logs'] = [
          {
            'id': 1,
            'actor_id': 'admin-1',
            'actor_kind': 'user',
            'action': 'UPDATE',
            'table_name': 'profiles',
            'row_key': {'id': monaId},
            'old_data': {'id': monaId, 'is_active': true, 'updated_at': 'a'},
            'new_data': {'id': monaId, 'is_active': false, 'updated_at': 'b'},
            'happened_at': '2026-11-01T10:00:00Z',
          },
          {
            'id': 2,
            'actor_id': null,
            'actor_kind': 'system',
            'action': 'UPDATE',
            'table_name': 'attendance_records',
            'row_key': {'id': 'day-1'},
            'old_data': {'employee_id': monaId, 'auto_closed': false},
            'new_data': {'employee_id': monaId, 'auto_closed': true},
            'happened_at': '2026-11-01T22:00:00Z',
          },
        ];
        final entries = await repository.getAuditHistory(monaId);
        expect(entries.map((e) => e.id), [2, 1]);
        // Bookkeeping columns are left out of the diff.
        expect(entries.last.changes, [
          (field: 'is_active', before: true, after: false),
        ]);
        expect(
          db.reads.map((r) => r.$2),
          containsAll(['row_key->>id', 'new_data->>employee_id']),
        );
      },
    );

    test('a refused activation is not allowed', () async {
      db.rpcError = Exception('x');
      await expectLater(
        repository.setEmployeeActive(monaId, active: true),
        throwsA(AdminFailure.network),
      );
      expect(
        SupabaseAdminRepository.failureFor(
          '42501',
          'This operation is only for employee accounts',
        ),
        AdminFailure.notAllowed,
      );
      expect(
        SupabaseAdminRepository.failureFor(
          '22023',
          'Employee profile not found',
        ),
        AdminFailure.notFound,
      );
    });
  });

  group('Pages', () {
    testWidgets('employee details: profile, stats, filters and days', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..employees = [mona()]
        ..schedules = schedules.toList()
        ..history = {
          monaId: [
            day(id: 'today', checkOut: DateTime.utc(2026, 11, 1, 11), late: 5),
          ],
        };
      await show(tester, const EmployeeDetailsView(id: monaId), admin);
      expect(tester.takeException(), isNull);
      expect(find.text('Mona Ali'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Morning (Africa/Cairo)'), findsOneWidget);
      expect(find.text('Late arrivals'), findsOneWidget);
      expect(find.text('5 min late'), findsOneWidget);
      expect(find.byKey(const Key('employeeDay-today')), findsOneWidget);
      expect(admin.activeChanges, isEmpty, reason: 'opening changes nothing');

      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('employeeDay-today')), findsOneWidget);

      await tester.tap(find.byKey(const Key('toggleActive')));
      await tester.pumpAndSettle();
      expect(find.text('Deactivate Mona Ali?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmDialog')));
      await tester.pumpAndSettle();
      expect(admin.activeChanges.single, (monaId, false));
      expect(find.text('Account status updated.'), findsOneWidget);
    });

    testWidgets('admin accounts can\'t be deactivated from the app', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..employees = [mona(role: UserRole.admin)]
        ..schedules = schedules.toList();
      await show(tester, const EmployeeDetailsView(id: monaId), admin);
      expect(find.byKey(const Key('toggleActive')), findsNothing);
    });

    testWidgets('day page: times, both photos and both locations', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..employees = [mona()]
        ..days = {
          'today': (
            employeeId: monaId,
            session: day(id: 'today', checkOut: DateTime.utc(2026, 11, 1, 11)),
          ),
        };
      await show(
        tester,
        const AdminAttendanceDayView(attendanceId: 'today', showMaps: false),
        admin,
      );
      expect(tester.takeException(), isNull);
      // Photos are signed for exactly this day's two events, in order.
      expect(admin.signed, ['$monaId/in-today.jpg', '$monaId/out-today.jpg']);
      final checkIn = find.byKey(const Key('checkInEvidence'));
      final checkOut = find.byKey(const Key('checkOutEvidence'));
      expect(
        find.descendant(of: checkIn, matching: find.text('30.044400')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: checkOut, matching: find.text('30.050000')),
        findsOneWidget,
      );
      expect(find.text('±12 m'), findsOneWidget);
      expect(find.text('Left early by'), findsOneWidget);
    });

    testWidgets('day page: missing photo, location and check-out', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..days = {
          'x': (
            employeeId: monaId,
            session: day(id: 'x', autoClosed: true, withEvidence: false),
          ),
        };
      await show(
        tester,
        const AdminAttendanceDayView(attendanceId: 'x', showMaps: false),
        admin,
      );
      expect(find.text('No photo was saved.'), findsOneWidget);
      expect(find.text('Location unavailable'), findsOneWidget);
      expect(find.text('No check-out was recorded.'), findsOneWidget);
      expect(admin.signed, isEmpty);
    });

    testWidgets('day page: an invalid coordinate is never shown', (
      tester,
    ) async {
      final admin = FakeAdminRepository()
        ..days = {
          'x': (employeeId: monaId, session: day(id: 'x', latitude: 123)),
        };
      await show(
        tester,
        const AdminAttendanceDayView(attendanceId: 'x', showMaps: false),
        admin,
      );
      expect(find.text('Location unavailable'), findsWidgets);
    });

    testWidgets('audit history lists who changed what', (tester) async {
      final admin = FakeAdminRepository()
        ..employees = [mona()]
        ..audit = [
          AuditEntryEntity(
            id: 1,
            actorId: monaId,
            actorKind: 'user',
            action: 'UPDATE',
            table: 'profiles',
            rowId: monaId,
            happenedAt: DateTime.utc(2026, 11, 1, 10),
            changes: const [(field: 'is_active', before: true, after: false)],
          ),
        ];
      await show(tester, const AuditHistoryView(employeeId: monaId), admin);
      expect(find.text('Changed · Profile'), findsOneWidget);
      expect(find.textContaining('by Mona Ali'), findsOneWidget);
      expect(find.text('is_active: true → false'), findsOneWidget);
    });

    testWidgets('Arabic, right to left, no overflow', (tester) async {
      final admin = FakeAdminRepository()
        ..employees = [mona()]
        ..schedules = schedules.toList()
        ..history = {
          monaId: [day(id: 'today', checkOut: DateTime.utc(2026, 11, 1, 11))],
        }
        ..days = {
          'today': (
            employeeId: monaId,
            session: day(id: 'today', checkOut: DateTime.utc(2026, 11, 1, 11)),
          ),
        };
      tester.view.physicalSize = const Size(360, 1600);
      await show(
        tester,
        const EmployeeDetailsView(id: monaId),
        admin,
        locale: const Locale('ar'),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('آخر 7 أيام'), findsOneWidget);
      await show(
        tester,
        const AdminAttendanceDayView(attendanceId: 'today', showMaps: false),
        admin,
        locale: const Locale('ar'),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('إثبات الحضور'), findsOneWidget);
    });
  });
}

/// The admin's reads and RPCs, for repository tests.
class _RecordingDatabase implements DatabaseServices {
  final rows = <String, List<Map<String, dynamic>>>{};
  final reads = <(String, String)>[];
  final rpcCalls = <(String, Map<String, dynamic>?)>[];
  Object? rpcError;

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
    final (key, value) = query!.entries.map((e) => (e.key, e.value)).single;
    reads.add((path, key));
    Object? field(Map<String, dynamic> row) => switch (key) {
      'row_key->>id' => (row['row_key'] as Map)['id'],
      'new_data->>employee_id' => (row['new_data'] as Map?)?['employee_id'],
      _ => row[key],
    };
    return [
      for (final row in rows[path] ?? const <Map<String, dynamic>>[])
        if (field(row) == value) row,
    ];
  }

  @override
  Future<dynamic> rpc({
    required String function,
    Map<String, dynamic>? params,
  }) async {
    if (rpcError case final error?) throw error;
    rpcCalls.add((function, params));
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
