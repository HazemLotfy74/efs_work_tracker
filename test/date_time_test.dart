import 'package:efs_work_tracker/core/enums/day_part.dart';
import 'package:efs_work_tracker/core/extensions/date_time_format.dart';
import 'package:efs_work_tracker/core/manager/clock_cubit.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Wednesday 14 May 2025, 8:07 AM (local time).
  final time = DateTime(2025, 5, 14, 8, 7);

  // intl puts a narrow no-break space (U+202F) before AM/PM.
  const eightOhSeven = '8:07 AM';

  /// Gives [check] a context in [locale], optionally on a 24-hour phone.
  Future<void> withContext(
    WidgetTester tester,
    void Function(BuildContext context) check, {
    Locale locale = const Locale('en'),
    bool use24Hour = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(alwaysUse24HourFormat: use24Hour),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            check(context);
            return const SizedBox();
          },
        ),
      ),
    );
  }

  group('DateTimeFormatX', () {
    testWidgets('English formats', (tester) async {
      await withContext(tester, (context) {
        expect(time.formatTime(context), eightOhSeven);
        expect(time.formatClock(context), '8:07');
        expect(time.formatWeekdayShort(context), 'Wed');
        expect(time.formatWeekday(context), 'Wednesday');
        expect(time.formatDayOfMonth(context), '14');
        expect(time.formatMonthDay(context), 'May 14');
        expect(time.formatMonthYear(context), 'May 2025');
        expect(time.formatShortDate(context), 'Wed, May 14');
        expect(time.formatLongDate(context), 'Wednesday, May 14');
        expect(time.formatFullDate(context), 'Wednesday, May 14, 2025');
      });
    });

    testWidgets('24-hour phones get 24-hour times', (tester) async {
      final evening = DateTime(2025, 5, 14, 20, 7);
      await withContext(use24Hour: true, tester, (context) {
        expect(evening.formatTime(context), '20:07');
        expect(evening.formatClock(context), '20:07');
      });
    });

    testWidgets('Arabic uses Arabic day and month names', (tester) async {
      await withContext(locale: const Locale('ar'), tester, (context) {
        expect(time.formatWeekday(context), 'الأربعاء');
        expect(time.formatMonthDay(context), contains('مايو'));
        expect(time.formatTime(context), contains('ص')); // AM
      });
    });

    testWidgets('UTC times are shown in local time', (tester) async {
      final utc = time.toUtc();
      await withContext(tester, (context) {
        expect(utc.formatTime(context), eightOhSeven);
      });
    });
  });

  test('DayPart.of picks the part of the day', () {
    expect(DayPart.of(DateTime(2025, 5, 14, 5)), DayPart.morning);
    expect(DayPart.of(DateTime(2025, 5, 14, 11, 59)), DayPart.morning);
    expect(DayPart.of(DateTime(2025, 5, 14, 12)), DayPart.afternoon);
    expect(DayPart.of(DateTime(2025, 5, 14, 16, 59)), DayPart.afternoon);
    expect(DayPart.of(DateTime(2025, 5, 14, 17)), DayPart.evening);
    expect(DayPart.of(DateTime(2025, 5, 14, 4, 59)), DayPart.evening);
  });

  testWidgets('ClockCubit ticks when the next minute starts', (tester) async {
    var now = DateTime(2025, 5, 14, 8, 7, 45);
    final clock = ClockCubit(now: () => now);

    expect(clock.state, now);

    // 15 seconds later the minute changes.
    now = DateTime(2025, 5, 14, 8, 8);
    await tester.pump(const Duration(seconds: 15));
    expect(clock.state, DateTime(2025, 5, 14, 8, 8));

    // Then every full minute.
    now = DateTime(2025, 5, 14, 8, 9);
    await tester.pump(const Duration(minutes: 1));
    expect(clock.state, DateTime(2025, 5, 14, 8, 9));

    // Closing cancels the timer (the test fails if a timer is left running).
    await clock.close();
  });
}
