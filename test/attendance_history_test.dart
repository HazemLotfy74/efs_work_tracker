import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:efs_work_tracker/app/features/history/data/repositories/supabase_history_repository.dart';
import 'package:efs_work_tracker/app/features/history/domain/repositories/history_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_event_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_type.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/shift_entity.dart';
import 'package:efs_work_tracker/app/features/history/domain/attendance_history_summary.dart';
import 'package:efs_work_tracker/app/features/history/presentation/manager/attendance_history_cubit/attendance_history_cubit.dart';
import 'package:efs_work_tracker/app/features/history/presentation/widgets/history_view_body.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'attendance_supabase_test.dart' show FakeServer, userId;

final now = DateTime(2025, 5, 14, 15, 33);
AttendanceSessionEntity day(
  int date, {
  int? hours = 8,
  int late = 0,
  bool closed = false,
}) {
  final start = DateTime(2025, 5, date, 8, 7);
  return AttendanceSessionEntity(
    id: 'day-$date',
    workDate: DateTime(2025, 5, date),
    shift: ShiftEntity.standard,
    checkIn: AttendanceEventEntity(type: AttendanceType.checkIn, time: start),
    checkOut: hours == null
        ? null
        : AttendanceEventEntity(
            type: AttendanceType.checkOut,
            time: start.add(Duration(hours: hours)),
          ),
    autoClosedAt: closed ? DateTime(2025, 5, date + 1) : null,
    closeDeadline: DateTime(2025, 5, date + 1),
    lateMinutes: late,
  );
}

class TestHistoryRepository implements HistoryRepository {
  List<AttendanceSessionEntity> rows = [
    day(14, hours: null),
    day(13),
    day(12, hours: 9, late: 23),
    day(9, hours: null, closed: true),
    day(8),
  ];
  bool fail = false;
  final requested = <DateTime?>[];
  Future<List<AttendanceSessionEntity>> Function(DateTime? month)? handler;
  @override
  Future<List<AttendanceSessionEntity>> getMonth(DateTime month) async {
    requested.add(month);
    if (fail) throw StateError('offline');
    if (handler != null) return handler!(month);
    return rows
        .where(
          (s) =>
              s.workDate!.year == month.year &&
              s.workDate!.month == month.month,
        )
        .toList();
  }
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Manrope');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Manrope-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  test('monthly totals exclude live and auto-closed hours', () {
    final summary = AttendanceHistorySummary(TestHistoryRepository().rows);
    expect(summary.days, 5);
    expect(summary.worked, const Duration(hours: 25));
    expect(summary.overtime, const Duration(hours: 1));
    expect(summary.lateDays, 1);
    expect(summary.lateMinutes, 23);
    expect(
      AttendanceHistoryFilter.needsReview.matches(
        day(9, hours: null, closed: true),
        now,
      ),
      isTrue,
    );
    expect(
      AttendanceHistoryFilter.overtime.matches(day(12, hours: 9), now),
      isTrue,
    );
  });

  test(
    'month query keeps employee ownership and year rollover boundaries',
    () async {
      final db = FakeServer();
      final repo = SupabaseHistoryRepository(
        databaseServices: db,
        currentUserId: () => userId,
      );
      await repo.getMonth(DateTime(2025, 12));
      expect(db.historyLower, {'work_date': '2025-12-01'});
      expect(db.historyUpper, {'work_date': '2026-01-01'});
      expect(db.reads.last.$2, {'employee_id': userId});
    },
  );

  test('refresh failure keeps records visibly stale', () async {
    final repo = TestHistoryRepository();
    final cubit = AttendanceHistoryCubit(repo, initialMonth: now);
    addTearDown(cubit.close);
    await cubit.load();
    repo.fail = true;
    await cubit.load();
    expect((cubit.state as AttendanceHistoryLoaded).stale, isTrue);
    expect((cubit.state as AttendanceHistoryLoaded).sessions, hasLength(5));
  });

  test('a slower old month cannot replace the selected month', () async {
    final repo = TestHistoryRepository();
    final first = Completer<List<AttendanceSessionEntity>>();
    repo.handler = (month) =>
        month!.month == 5 ? first.future : Future.value([]);
    final cubit = AttendanceHistoryCubit(repo, initialMonth: now);
    addTearDown(cubit.close);
    final pending = cubit.load();
    await cubit.selectMonth(DateTime(2025, 6));
    first.complete([day(14)]);
    await pending;
    expect(cubit.month, DateTime(2025, 6));
    expect((cubit.state as AttendanceHistoryLoaded).sessions, isEmpty);
  });

  Future<void> showHistory(
    WidgetTester tester, {
    Size size = const Size(430, 932),
    double scale = 1,
    String language = 'en',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = AttendanceHistoryCubit(
      TestHistoryRepository(),
      initialMonth: now,
    );
    final clock = ClockCubit(now: () => now);
    await cubit.load();
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
          path: '/history',
          builder: (context, state) => RepaintBoundary(
            key: const Key('preview'),
            child: Scaffold(
              body: const SafeArea(child: HistoryViewBody()),
              bottomNavigationBar: NavigationBar(
                selectedIndex: 1,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    label: 'History',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notifications_outlined),
                    label: 'Alerts',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/attendance/:id',
          builder: (context, state) =>
              Scaffold(body: Text(state.pathParameters['id']!)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => cubit),
          BlocProvider(create: (_) => clock),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'search, filters, month navigation, date selection and row navigation work',
    (tester) async {
      await showHistory(tester);
      expect(find.text('May 2025'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '2025-05-12');
      await tester.pumpAndSettle();
      expect(find.text('1 record'), findsOneWidget);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Late'));
      await tester.pumpAndSettle();
      expect(find.text('1 record'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('June 2025'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Choose a date'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2025-05-12');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('23 min late'));
      await tester.tap(find.text('23 min late'));
      await tester.pumpAndSettle();
      expect(find.text('day-12'), findsOneWidget);
    },
  );

  for (final (name, size, scale, language) in [
    ('phone', const Size(430, 932), 1.0, 'en'),
    ('small', const Size(320, 568), 1.0, 'en'),
    ('tablet', const Size(1024, 768), 1.0, 'en'),
    ('arabic-large', const Size(320, 568), 2.0, 'ar'),
  ]) {
    testWidgets('history adapts to $name', (tester) async {
      await showHistory(tester, size: size, scale: scale, language: language);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Optional review artifact; normal test runs create no files.
      const previews = String.fromEnvironment('HISTORY_PREVIEW_DIR');
      if (previews.isNotEmpty) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000));
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('preview')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$previews/history-$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
