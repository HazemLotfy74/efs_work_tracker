import 'dart:convert';

import 'package:efs_work_tracker/app/features/attendance_session/data/repositories/supabase_attendance_repository.dart';
import 'package:efs_work_tracker/app/features/history/data/repositories/supabase_history_repository.dart';
import 'package:efs_work_tracker/core/errors/attendance_errors.dart';
import 'package:efs_work_tracker/core/services/supabase_database_services.dart';
import 'package:efs_work_tracker/app/features/history/presentation/views/history_view.dart';
import 'package:efs_work_tracker/app/features/history/presentation/widgets/history_view_body.dart';
import 'package:efs_work_tracker/app/features/history/presentation/manager/attendance_history_cubit/attendance_history_cubit.dart';
import 'package:efs_work_tracker/app/features/main_layout/presentation/views/main_layout_view.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';

import 'helpers/app_providers.dart';
import 'attendance_supabase_test.dart' show FakeServer, FakeStorage;

const _employee = '11111111-1111-4111-8111-111111111111';

/// Synthetic data matching the schema inspected on the live project.
/// No employee identifiers, locations, photos or production rows are stored.
Map<String, Object?> _record({bool closed = false, bool completed = true}) => {
  'id': '22222222-2222-4222-8222-222222222222',
  'work_date': '2026-11-01',
  'timezone': 'Africa/Cairo',
  'scheduled_start': '2026-11-01T06:00:00+00:00',
  'scheduled_end': '2026-11-01T14:00:00+00:00',
  'grace_minutes': 15,
  'actual_checkin': '2026-11-01T06:07:00+00:00',
  'actual_checkout': completed ? '2026-11-01T15:10:00+00:00' : null,
  'auto_closed': closed,
  'auto_closed_at': closed ? '2026-11-01T22:00:00+00:00' : null,
  'auto_close_policy': 'midnight',
  'auto_close_deadline': '2026-11-01T22:00:00+00:00',
  'effective_checkin': '2026-11-01T06:07:00+00:00',
  'effective_checkout': completed ? '2026-11-01T15:10:00+00:00' : null,
  'has_correction': false,
  'late_minutes': 0,
  'attendance_events': [
    {
      'event_type': 'check_in',
      'occurred_at': '2026-11-01T06:07:00+00:00',
      'latitude': 0,
      'longitude': 0,
      'accuracy_m': 8,
      'selfie_path': 'synthetic/checkin.jpg',
    },
    if (completed)
      {
        'event_type': 'check_out',
        'occurred_at': '2026-11-01T15:10:00+00:00',
        'latitude': 0,
        'longitude': 0,
        'accuracy_m': 8,
        'selfie_path': 'synthetic/checkout.jpg',
      },
  ],
};

void main() {
  SupabaseHistoryRepository repository(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'synthetic-publishable-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(handler),
    );
    addTearDown(client.dispose);
    return SupabaseHistoryRepository(
      databaseServices: SupabaseDatabaseServices(client: client),
      currentUserId: () => _employee,
    );
  }

  test(
    'SDK sends owner and month filters and decodes embedded events',
    () async {
      late http.Request sent;
      final repo = repository((request) async {
        sent = request;
        return http.Response(
          jsonEncode([_record()]),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      });
      final history = await repo.getMonth(DateTime(2026, 11));
      expect(sent.method, 'GET');
      expect(sent.url.path, '/rest/v1/attendance_records');
      expect(sent.url.queryParameters['employee_id'], 'eq.$_employee');
      expect(
        sent.url.queryParametersAll['work_date'],
        containsAll(['gte.2026-11-01', 'lt.2026-12-01']),
      );
      expect(sent.url.queryParameters['order'], 'work_date.desc.nullslast');
      expect(sent.url.queryParameters['limit'], '60');
      expect(
        sent.url.queryParameters['select'],
        contains('attendance_events('),
      );
      expect(sent.headers['apikey'], 'synthetic-publishable-key');
      expect(history, hasLength(1));
      final day = history.single;
      expect(day.workDate, DateTime(2026, 11, 1));
      expect(day.timezone, 'Africa/Cairo');
      expect(day.shift.start, const Duration(hours: 8));
      expect(
        day.verifiedDuration!.worked,
        const Duration(hours: 9, minutes: 3),
      );
      expect(
        day.verifiedDuration!.overtime,
        const Duration(hours: 1, minutes: 3),
      );
      expect(day.checkIn.selfiePath, 'synthetic/checkin.jpg');
      expect(day.checkOut!.location!.accuracyMeters, 8);
    },
  );

  test('SDK handles an empty month without demo records', () async {
    final repo = repository(
      (request) async => http.Response('[]', 200, request: request),
    );
    expect(await repo.getMonth(DateTime(2026, 10)), isEmpty);
  });

  testWidgets(
    'History navigation displays records from the Supabase repository',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final database = FakeServer()..recordsOverride = [_record()];
      final repo = SupabaseAttendanceRepository(
        databaseServices: database,
        storageServices: FakeStorage(),
        currentUserId: () => _employee,
      );
      final historyRepo = SupabaseHistoryRepository(
        databaseServices: database,
        currentUserId: () => _employee,
      );
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) =>
                MainLayoutView(navigationShell: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/history',
                    builder: (_, _) => const HistoryView(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/notifications',
                    builder: (_, _) => const SizedBox(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (_, _) => const SizedBox(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        withAppProviders(
          MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
          repository: repo,
          history: historyRepo,
        ),
      );
      await tester.pump();
      await tester.tap(find.text('History'));
      await tester.pump();
      final cubit = tester
          .element(find.byType(HistoryViewBody))
          .read<AttendanceHistoryCubit>();
      await tester.pumpAndSettle();
      expect(cubit.state, isA<AttendanceHistoryLoaded>());
      expect(find.text('Attendance history'), findsOneWidget);
      expect(find.text('1 record'), findsOneWidget);
      expect(find.text('9h 3m'), findsWidgets);
      expect(
        database.reads.any(
          (read) =>
              read.$1 == 'attendance_records' &&
              read.$2?['employee_id'] == _employee,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('SDK preserves unconfirmed auto-closed hours', () async {
    final repo = repository(
      (request) async => http.Response(
        jsonEncode([_record(closed: true, completed: false)]),
        200,
        request: request,
      ),
    );
    final result = await repo.getMonth(DateTime(2026, 11));
    expect(result.single.needsReview, isTrue);
    expect(result.single.verifiedDuration, isNull);
  });

  test(
    'API permission failures are surfaced rather than shown as no history',
    () async {
      final repo = repository(
        (request) async => http.Response(
          jsonEncode({
            'code': '42501',
            'message': 'permission denied',
            'details': null,
            'hint': null,
          }),
          403,
          request: request,
        ),
      );
      await expectLater(
        repo.getMonth(DateTime(2026, 11)),
        throwsA(AttendanceFailure.accountNotReady),
      );
    },
  );
}
