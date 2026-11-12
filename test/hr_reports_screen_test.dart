import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/hr_reports/data/hr_workbook.dart';
import 'package:efs_work_tracker/app/features/hr_reports/data/repositories/supabase_hr_report_repository.dart';
import 'package:efs_work_tracker/app/features/hr_reports/domain/entities/hr_report.dart';
import 'package:efs_work_tracker/app/features/hr_reports/domain/hr_report_builder.dart';
import 'package:efs_work_tracker/app/features/hr_reports/domain/repositories/hr_report_repository.dart';
import 'package:efs_work_tracker/app/features/hr_reports/presentation/manager/hr_reports_cubit/hr_reports_cubit.dart';
import 'package:efs_work_tracker/app/features/hr_reports/presentation/views/hr_reports_view.dart';
import 'package:efs_work_tracker/core/errors/admin_errors.dart';
import 'package:efs_work_tracker/core/services/database_services.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_providers.dart';
import 'helpers/fake_admin_repository.dart';
import 'hr_reports_test.dart'
    show cairo, generatedAt, input, person, scheduleId;

void main() {
  const builder = HrReportBuilder(localWallTime);

  group('HrReportsCubit', () {
    late FakeHrRepository repository;
    HrReportsCubit cubit() {
      final cubit = HrReportsCubit(
        repository,
        builder,
        generatedBy: 'Test Admin',
        now: () => generatedAt,
        // Same bytes the background isolate makes, without the isolate.
        encode: (report) async => HrWorkbook.encode(report),
      );
      addTearDown(cubit.close);
      return cubit;
    }

    setUp(() => repository = FakeHrRepository(input()));

    test('loads this month, never a future one', () async {
      final reports = cubit();
      await reports.load();
      expect(reports.state, isA<HrReportsLoaded>());
      expect(reports.state.period, HrReportPeriod(2026, 11));
      expect(repository.loads.single, (HrReportPeriod(2026, 11), 'Test Admin'));

      await reports.next();
      expect(reports.state.period, HrReportPeriod(2026, 11));
      expect(repository.loads, hasLength(1));

      await reports.previous();
      expect(reports.state.period, HrReportPeriod(2026, 10));
    });

    test('a failed load shows why and can be retried', () async {
      repository.failure = AdminFailure.network;
      final reports = cubit();
      await reports.load();
      expect((reports.state as HrReportsError).failure, AdminFailure.network);

      repository.failure = null;
      await reports.load();
      expect(reports.state, isA<HrReportsLoaded>());
    });

    test('export builds the workbook and shares it once', () async {
      final reports = cubit();
      await reports.load();
      final first = reports.export();
      expect((reports.state as HrReportsLoaded).exporting, isTrue);
      await reports.export(); // ignored while the first one runs
      await first;

      expect(repository.shared.single.$2, 'Attendance_Report_2026_11.xlsx');
      final book = ZipDecoder().decodeBytes(repository.shared.single.$1);
      expect(book.findFile('xl/workbook.xml'), isNotNull);
      final state = reports.state as HrReportsLoaded;
      expect(state.exporting, isFalse);
      expect(state.exported, isTrue);
    });

    test('a failed share is reported, not swallowed', () async {
      repository.shareFailure = AdminFailure.unknown;
      final reports = cubit();
      await reports.load();
      await reports.export();
      final state = reports.state as HrReportsLoaded;
      expect(state.exportFailed, isTrue);
      expect(state.exporting, isFalse);
    });
  });

  group('SupabaseHrReportRepository', () {
    test('reads one month and keeps only its corrections', () async {
      final database = FakeReportDatabase();
      final admin = FakeAdminRepository()
        ..employees = [person('mona', 'Mona Ali')];
      final repository = SupabaseHrReportRepository(
        admin: admin,
        databaseServices: database,
        now: () => generatedAt,
      );

      final loaded = await repository.load(
        HrReportPeriod(2026, 11),
        generatedBy: 'Test Admin',
      );

      final (from, to) = database.reads['attendance_records']!;
      expect(from, {'work_date': '2026-11-01'});
      expect(to, {'work_date': '2026-12-01'});
      expect(database.reads['attendance_correction_requests']!.$1, {
        'created_at': '2026-11-01T00:00:00Z',
      });
      expect(loaded.employees.single.id, 'mona');
      expect(
        loaded.schedules.single.days.single.start,
        const Duration(hours: 8),
      );
      expect(loaded.days['mona']!.single.id, 'mona-1');
      expect(loaded.corrections.map((c) => c.id), ['c-1']);
      expect(loaded.generatedBy, 'Test Admin');
    });

    test('database errors become admin failures', () async {
      final repository = SupabaseHrReportRepository(
        admin: FakeAdminRepository(),
        databaseServices: FakeReportDatabase()..error = Exception('offline'),
      );
      await expectLater(
        repository.load(HrReportPeriod(2026, 11), generatedBy: ''),
        throwsA(AdminFailure.network),
      );
    });

    test('share keeps only the newest report file', () async {
      final folder = Directory(
        '${Directory.systemTemp.path}/hr_reports_share_test',
      );
      final sharedFiles = <String>[];
      final repository = SupabaseHrReportRepository(
        admin: FakeAdminRepository(),
        databaseServices: FakeReportDatabase(),
        folder: () async => folder,
        share: (file, name) async => sharedFiles.add(file.path),
      );
      await repository.share(Uint8List.fromList([1, 2]), 'old.xlsx');
      await repository.share(Uint8List.fromList([3]), 'new.xlsx');

      expect(sharedFiles.last, endsWith('new.xlsx'));
      expect(folder.listSync().map((f) => f.uri.pathSegments.last), [
        'new.xlsx',
      ]);
      folder.deleteSync(recursive: true);
    });
  });

  group('HR reports screen', () {
    Future<void> show(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      double width = 390,
    }) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        withAppProviders(
          user: const UserEntity(
            uID: 'admin-1',
            email: 'admin@example.com',
            fullName: 'Test Admin',
            username: 'test.admin',
            employeeCode: 'ADM-1',
            role: UserRole.admin,
            isActive: true,
            mustChangePassword: false,
          ),
          RepositoryProvider<HrReportRepository>.value(
            value: FakeHrRepository(input()),
            child: MaterialApp(
              theme: AppTheme.lightFor(locale),
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HrReportsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the month figures and the export button', (
      tester,
    ) async {
      await show(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('HR reports'), findsOneWidget);
      expect(find.text('Absences (no record)'), findsOneWidget);
      expect(find.text('3.5 h'), findsOneWidget); // calculated overtime
      expect(find.text('Generate Excel'), findsOneWidget);
      // The current month is the newest: "next" is disabled.
      final next = tester.widget<IconButton>(
        find.byKey(const Key('hrNextMonth')),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('fits a small phone in Arabic', (tester) async {
      await show(tester, locale: const Locale('ar'), width: 320);
      expect(tester.takeException(), isNull);
      expect(find.text('تقارير الموارد البشرية'), findsOneWidget);
      expect(find.text('إنشاء ملف Excel'), findsOneWidget);
    });
  });
}

/// Records what the cubit asks for; never touches a database or files.
class FakeHrRepository implements HrReportRepository {
  FakeHrRepository(this.input);

  final HrReportInput input;
  AdminFailure? failure;
  AdminFailure? shareFailure;
  final loads = <(HrReportPeriod, String)>[];
  final shared = <(Uint8List, String)>[];

  @override
  Future<HrReportInput> load(
    HrReportPeriod period, {
    required String generatedBy,
    String? employeeId,
  }) async {
    loads.add((period, generatedBy));
    if (failure case final failure?) throw failure;
    return HrReportInput(
      period: period,
      employees: input.employees,
      schedules: input.schedules,
      days: period == input.period ? input.days : const {},
      corrections: input.corrections,
      generatedAt: input.generatedAt,
      generatedBy: generatedBy,
    );
  }

  @override
  Future<void> share(Uint8List bytes, String fileName) async {
    await Future<void>.delayed(Duration.zero);
    if (shareFailure case final failure?) throw failure;
    shared.add((bytes, fileName));
  }
}

/// The tables the HR report reads, as an admin sees them through RLS.
class FakeReportDatabase implements DatabaseServices {
  final reads = <String, (Map<String, Object>?, Map<String, Object>?)>{};
  Exception? error;

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
    if (error case final error?) throw error;
    reads[path] = (greaterThanOrEqual, lessThan);
    return switch (path) {
      'work_schedules' => [
        {
          'id': scheduleId,
          'name': 'Standard',
          'timezone': 'Africa/Cairo',
          'schedule_days': [
            {'weekday': 0, 'starts_at': '08:00:00', 'ends_at': '16:00:00'},
          ],
        },
      ],
      'attendance_records' => [
        {
          'id': 'mona-1',
          'employee_id': 'mona',
          'work_date': '2026-11-01',
          'timezone': 'Africa/Cairo',
          'scheduled_start': cairo(1, 8).toIso8601String(),
          'scheduled_end': cairo(1, 16).toIso8601String(),
          'grace_minutes': 15,
          'actual_checkin': cairo(1, 8).toIso8601String(),
          'actual_checkout': cairo(1, 16).toIso8601String(),
          'auto_closed': false,
          'auto_closed_at': null,
          'auto_close_policy': 'midnight',
          'auto_close_deadline': cairo(2, 0).toIso8601String(),
          'effective_checkin': cairo(1, 8).toIso8601String(),
          'effective_checkout': cairo(1, 16).toIso8601String(),
          'has_correction': false,
          'late_minutes': 0,
        },
      ],
      'attendance_correction_requests' => [
        for (final (id, attendance) in [('c-1', 'mona-1'), ('c-2', 'other')])
          {
            'id': id,
            'employee_id': 'mona',
            'attendance_id': attendance,
            'proposed_checkin': cairo(1, 8).toIso8601String(),
            'proposed_checkout': cairo(1, 16).toIso8601String(),
            'reason': 'Forgot to check out',
            'status': 'pending',
            'review_note': null,
            'reviewed_at': null,
            'created_at': cairo(2, 9).toIso8601String(),
          },
      ],
      _ => const [],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
