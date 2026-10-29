import 'package:efs_work_tracker/app/features/attendance_session/data/repositories/in_memory_attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_event_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_type.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/location_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/shift_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/repositories/attendance_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/views/attendance_success_view.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/review/early_departure_notice.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/review/review_summary_card.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/today_attendance_card.dart';
import 'package:efs_work_tracker/core/errors/attendance_errors.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_providers.dart';

void main() {
  // intl puts a narrow no-break space (U+202F) before AM/PM.
  const eightOhSeven = '8:07 AM';

  final location = LocationEntity(
    latitude: 30.0275,
    longitude: 31.4913,
    accuracyMeters: 8,
    capturedAt: DateTime.utc(2025, 5, 14, 8, 7),
  );

  /// A finished flow: time, location and selfie captured.
  AttendanceEventEntity event(AttendanceType type, DateTime time) =>
      AttendanceEventEntity(
        type: type,
        time: time,
        location: location,
        selfiePath: '/tmp/selfie.jpg',
        selfieCapturedAt: time,
      );

  // Wednesday 14 May 2025: in at 8:07 AM, out at 3:26 PM.
  final checkInTime = DateTime(2025, 5, 14, 8, 7);
  final checkOutTime = DateTime(2025, 5, 14, 15, 26);

  group('AttendanceSessionEntity', () {
    test('worked time runs while active and stops at check-out', () {
      final session = AttendanceSessionEntity(
        id: '1',
        checkIn: event(AttendanceType.checkIn, checkInTime),
        shift: ShiftEntity.standard,
      );
      expect(session.isActive, isTrue);
      expect(
        session.workedDuration(DateTime(2025, 5, 14, 9, 7)),
        const Duration(hours: 1),
      );
      expect(session.earlyLeave, Duration.zero);

      final finished = session.copyWith(
        checkOut: event(AttendanceType.checkOut, checkOutTime),
      );
      expect(finished.isActive, isFalse);
      expect(finished.workedDuration(), const Duration(hours: 7, minutes: 19));
      // Early leave is what's missing from 8 regular hours.
      expect(finished.earlyLeave, const Duration(minutes: 41));
    });
  });

  group('InMemoryAttendanceRepository', () {
    test('one session per day, check-out only the active one', () async {
      final repo = InMemoryAttendanceRepository();
      final now = DateTime.now();

      expect((await repo.getToday()).session, isNull);

      final session = await repo.checkIn(event(AttendanceType.checkIn, now));
      expect((await repo.getToday()).session, isNotNull);
      expect(
        () => repo.checkIn(event(AttendanceType.checkIn, now)),
        throwsA(AttendanceFailure.alreadyCheckedIn),
      );

      final finished = await repo.checkOut(
        session,
        event(AttendanceType.checkOut, now),
      );
      expect(finished.isActive, isFalse);
      expect(
        () => repo.checkOut(finished, event(AttendanceType.checkOut, now)),
        throwsA(AttendanceFailure.alreadyCheckedOut),
      );
    });
  });

  group('AttendanceSessionCubit', () {
    test('load, then record a check-in and a check-out', () async {
      final cubit = AttendanceSessionCubit(InMemoryAttendanceRepository());
      addTearDown(cubit.close);

      await cubit.load();
      var state = cubit.state as AttendanceSessionLoaded;
      expect(state.session, isNull);
      expect(state.shift, ShiftEntity.standard);

      await cubit.record(event(AttendanceType.checkIn, DateTime.now()));
      state = cubit.state as AttendanceSessionLoaded;
      expect(state.session!.isActive, isTrue);

      await cubit.record(event(AttendanceType.checkOut, DateTime.now()));
      state = cubit.state as AttendanceSessionLoaded;
      expect(state.session!.isActive, isFalse);
    });

    test('check-out without a check-in fails', () async {
      final cubit = AttendanceSessionCubit(InMemoryAttendanceRepository());
      addTearDown(cubit.close);
      await cubit.load();

      expect(
        () => cubit.record(event(AttendanceType.checkOut, DateTime.now())),
        throwsA(AttendanceFailure.notCheckedIn),
      );
    });
  });

  /// Shows [child] in the app with the app-wide providers.
  Future<void> show(
    WidgetTester tester,
    Widget child, {
    AttendanceRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      withAppProviders(
        repository: repository,
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump(); // session loaded
  }

  AttendanceSessionCubit sessionCubit(WidgetTester tester) =>
      tester.element(find.byType(MaterialApp)).read<AttendanceSessionCubit>();

  group('success screens', () {
    testWidgets('check-in shows the confirmed time and date', (tester) async {
      await show(
        tester,
        const AttendanceSuccessView(type: AttendanceType.checkIn),
      );
      await sessionCubit(tester)
          .record(event(AttendanceType.checkIn, checkInTime));
      // The cubit's new state reaches widgets on the next frame.
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Checked In'), findsOneWidget);
      expect(find.text('You’re all set!'), findsOneWidget);
      expect(find.text(eightOhSeven), findsOneWidget);
      expect(find.text('Wednesday, May 14'), findsOneWidget);
      expect(find.text('Return to home'), findsOneWidget);
    });

    testWidgets('check-out shows the final duration and early leave', (
      tester,
    ) async {
      await show(
        tester,
        const AttendanceSuccessView(type: AttendanceType.checkOut),
      );
      final cubit = sessionCubit(tester);
      await cubit.record(event(AttendanceType.checkIn, checkInTime));
      await cubit.record(event(AttendanceType.checkOut, checkOutTime));
      // The cubit's new state reaches widgets on the next frame.
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Checked Out'), findsOneWidget);
      expect(find.text('Workday recorded'), findsOneWidget);
      expect(find.textContaining('flagged for review'), findsOneWidget);
      expect(find.text('Final duration'), findsOneWidget);
      expect(find.text('7h 19m'), findsOneWidget);
      expect(find.text('View attendance details'), findsOneWidget);
    });
  });

  testWidgets('check-out review shows duration, early leave and warning', (
    tester,
  ) async {
    final session = AttendanceSessionEntity(
      id: '1',
      checkIn: event(AttendanceType.checkIn, checkInTime),
      shift: ShiftEntity.standard,
    );
    final checkOut = event(AttendanceType.checkOut, checkOutTime);
    final earlyLeave = session.earlyLeaveFor(checkOutTime);

    await show(
      tester,
      Column(
        children: [
          ReviewSummaryCard(
            event: checkOut,
            session: session,
            earlyLeave: earlyLeave,
          ),
          EarlyDepartureNotice(earlyLeave: earlyLeave),
        ],
      ),
    );

    expect(find.text('Check-out time'), findsOneWidget);
    expect(find.text('Recorded duration'), findsOneWidget);
    expect(find.text('7h 19m'), findsOneWidget);
    expect(find.text('41m'), findsOneWidget);
    expect(find.text('Early departure'), findsOneWidget);
    expect(find.textContaining('41m short of 8 regular hours'), findsOneWidget);
  });

  testWidgets('home card: not checked in → live timer → checked out', (
    tester,
  ) async {
    // A shift lasting all day, so the result doesn't depend on when the test
    // runs (after the shift end the card shows the automatic close).
    await show(
      tester,
      const SingleChildScrollView(child: TodayAttendanceCard()),
      repository: InMemoryAttendanceRepository(
        shift: const ShiftEntity(
          start: Duration.zero,
          end: Duration(hours: 24),
        ),
      ),
    );
    expect(find.text('Check In Now'), findsOneWidget);

    // Checked in an hour ago: the card shows a running timer.
    final cubit = sessionCubit(tester);
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    await cubit.record(event(AttendanceType.checkIn, oneHourAgo));
    // The cubit's new state reaches widgets on the next frame.
    await tester.pump();
    await tester.pump();

    expect(find.text('Elapsed working time'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Check out'), findsOneWidget);
    // Elapsed time as HH:MM:SS. (Tests can't watch it tick: the test clock
    // doesn't move DateTime.now.)
    expect(find.textContaining('01:00:'), findsOneWidget);

    // After check-out: total time and the details button.
    await cubit.record(event(AttendanceType.checkOut, DateTime.now()));
    // The cubit's new state reaches widgets on the next frame.
    await tester.pump();
    await tester.pump();

    expect(find.text('Checked Out'), findsWidgets);
    expect(find.text('Total working time'), findsOneWidget);
    expect(find.text('1h 0m'), findsOneWidget);
    expect(find.text('View attendance details'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
  });
}
