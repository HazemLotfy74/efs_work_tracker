import 'package:efs_work_tracker/app/features/attendance_session/data/repositories/supabase_attendance_repository.dart';
import 'package:efs_work_tracker/core/errors/attendance_errors.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_event_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_type.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/shift_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/not_checked_in_custom_container.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// Sunday 15 November 2026, Africa/Cairo = UTC+2: shift 08:00–16:00 Cairo.
final opens = DateTime.utc(2026, 11, 15, 6);
final closes = DateTime.utc(2026, 11, 15, 14);
final shift = ShiftEntity(
  start: const Duration(hours: 8),
  end: const Duration(hours: 16),
  startsAt: opens,
  endsAt: closes,
);

void main() {
  group('check-in window (same rule as the server check_in)', () {
    final today = AttendanceSessionLoaded(shift: shift);
    CheckInAvailability at(DateTime now) => today.checkInAt(now);

    test('boundaries', () {
      expect(
        at(opens.subtract(const Duration(seconds: 1))),
        CheckInAvailability.notYetOpen,
      );
      expect(at(opens), CheckInAvailability.open); // exactly 08:00
      expect(
        at(closes.subtract(const Duration(minutes: 1))),
        CheckInAvailability.open,
      );
      expect(at(closes), CheckInAvailability.closed); // exactly 16:00
      expect(
        at(closes.add(const Duration(minutes: 1))),
        CheckInAvailability.closed,
      );
    });

    test('instants, so the phone timezone cannot shift the window', () {
      // The same instant expressed in local time compares equal.
      expect(at(opens.toLocal()), CheckInAvailability.open);
    });

    test('day off and an existing check-in', () {
      expect(
        const AttendanceSessionLoaded(shift: null).checkInAt(opens),
        CheckInAvailability.notWorkingDay,
      );
      final checkedIn = AttendanceSessionLoaded(
        shift: shift,
        session: AttendanceSessionEntity(
          id: 'today',
          checkIn: AttendanceEventEntity(
            type: AttendanceType.checkIn,
            time: opens.add(const Duration(minutes: 5)),
          ),
          shift: shift,
        ),
      );
      expect(checkedIn.checkInAt(opens), CheckInAvailability.alreadyCheckedIn);
      expect(checkedIn.canCheckInAt(opens), isFalse);
    });
  });

  group('server refusals', () {
    AttendanceFailure map(String message) =>
        SupabaseAttendanceRepository.failureFor('22023', message);

    test('too early is not shown as a bad location', () {
      expect(
        map('Check-in opens at the scheduled shift start'),
        AttendanceFailure.checkInNotOpen,
      );
      expect(map('Check-in opens at 07:00'), AttendanceFailure.checkInNotOpen);
      expect(
        map('The check-in window has closed'),
        AttendanceFailure.checkInClosed,
      );
      // The other 22023 refusals keep their meaning.
      expect(
        map('Valid GPS coordinates and accuracy are required'),
        AttendanceFailure.invalidLocation,
      );
      expect(map('A selfie is required'), AttendanceFailure.selfieMissing);
    });
  });

  group('home card', () {
    Future<void> show(
      WidgetTester tester,
      CheckInAvailability availability, {
      ShiftEntity? withShift,
      Locale locale = const Locale('en'),
    }) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => ClockCubit(now: () => opens),
          child: MaterialApp(
            theme: AppTheme.lightFor(locale),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: NotCheckedInCustomContainer(
                  shift: withShift,
                  availability: availability,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    FilledButton? button(WidgetTester tester) {
      final finder = find.descendant(
        of: find.byKey(const Key('checkInNow')),
        matching: find.byType(FilledButton),
      );
      return finder.evaluate().isEmpty ? null : tester.widget(finder);
    }

    testWidgets('open: enabled, no reason', (tester) async {
      await show(tester, CheckInAvailability.open, withShift: shift);
      expect(button(tester)!.onPressed, isNotNull);
      expect(find.byKey(const Key('checkInReason')), findsNothing);
    });

    testWidgets('before opening: disabled, says when it opens', (tester) async {
      await show(tester, CheckInAvailability.notYetOpen, withShift: shift);
      expect(button(tester)!.onPressed, isNull);
      expect(find.textContaining('Check-in opens at 8:00'), findsOneWidget);
    });

    testWidgets('after closing: disabled, says it is closed', (tester) async {
      await show(tester, CheckInAvailability.closed, withShift: shift);
      expect(button(tester)!.onPressed, isNull);
      expect(find.textContaining('check-in is closed'), findsOneWidget);
    });

    testWidgets('day off: no button', (tester) async {
      await show(tester, CheckInAvailability.notWorkingDay);
      expect(button(tester), isNull);
      expect(find.textContaining('not a working day'), findsOneWidget);
    });

    testWidgets('Arabic, small phone: no overflow', (tester) async {
      await show(
        tester,
        CheckInAvailability.notYetOpen,
        withShift: shift,
        locale: const Locale('ar'),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('يبدأ تسجيل الحضور'), findsOneWidget);
    });
  });
}
