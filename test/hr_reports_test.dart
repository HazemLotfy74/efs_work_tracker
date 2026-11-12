import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/employee_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/domain/entities/correction_request_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/attendance_session_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/data/models/shift_model.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/auth/domain/entities/user_entity.dart';
import 'package:efs_work_tracker/app/features/hr_reports/data/hr_workbook.dart';
import 'package:efs_work_tracker/app/features/hr_reports/data/repositories/supabase_hr_report_repository.dart';
import 'package:efs_work_tracker/app/features/hr_reports/data/xlsx/xlsx_writer.dart';
import 'package:efs_work_tracker/app/features/hr_reports/domain/entities/hr_report.dart';
import 'package:efs_work_tracker/app/features/hr_reports/domain/hr_report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

// November 2026, Africa/Cairo = UTC+2. Schedule Sun–Thu 08:00–16:00.
// 1 Nov is a Sunday; the report is made on Friday 6 Nov at 12:00 Cairo.
const scheduleId = 'schedule-1';
final generatedAt = DateTime.utc(2026, 11, 6, 10);

/// 08:00 Cairo on [day] of November as a UTC instant, plus [h]:[m].
DateTime cairo(int day, int h, [int m = 0]) =>
    DateTime.utc(2026, 11, day, h - 2, m);

EmployeeEntity person(
  String id,
  String name, {
  bool active = true,
  DateTime? createdAt,
}) => EmployeeEntity(
  id: id,
  fullName: name,
  username: id,
  employeeCode: 'EMP-$id',
  role: UserRole.employee,
  isActive: active,
  mustChangePassword: false,
  scheduleId: scheduleId,
  createdAt: createdAt ?? DateTime.utc(2026, 10, 1),
);

/// An `attendance_records` row as the admin reads it.
AttendanceSessionEntity day(
  String employeeId,
  int date, {
  required DateTime checkIn,
  DateTime? checkOut,
  bool autoClosed = false,
  DateTime? correctedIn,
  DateTime? correctedOut,
  int late = 0,
}) {
  final json = <String, dynamic>{
    'id': '$employeeId-$date',
    'employee_id': employeeId,
    'work_date': '2026-11-${date.toString().padLeft(2, '0')}',
    'timezone': 'Africa/Cairo',
    'scheduled_start': cairo(date, 8).toIso8601String(),
    'scheduled_end': cairo(date, 16).toIso8601String(),
    'grace_minutes': 15,
    'actual_checkin': checkIn.toIso8601String(),
    'actual_checkout': checkOut?.toIso8601String(),
    'auto_closed': autoClosed,
    'auto_closed_at': autoClosed ? cairo(date + 1, 0).toIso8601String() : null,
    'auto_close_policy': 'midnight',
    'auto_close_deadline': cairo(date + 1, 0).toIso8601String(),
    'effective_checkin': (correctedIn ?? checkIn).toIso8601String(),
    'effective_checkout': (correctedOut ?? checkOut)?.toIso8601String(),
    'has_correction': correctedIn != null,
    'late_minutes': late,
  };
  return AttendanceSessionModel.fromJson(
    json,
    shift: ShiftModel.fromRecord(json),
  );
}

CorrectionRequestEntity correction(String attendanceId, CorrectionStatus s) =>
    CorrectionRequestEntity(
      id: 'c-$attendanceId-${s.name}',
      employeeId: 'mona',
      attendanceId: attendanceId,
      proposedCheckIn: cairo(3, 8),
      proposedCheckOut: cairo(3, 16),
      reason: 'Forgot to check out',
      status: s,
      createdAt: cairo(4, 9),
    );

final schedule = ReportSchedule(
  id: scheduleId,
  name: 'Standard',
  timezone: 'Africa/Cairo',
  days: [
    for (final dow in [0, 1, 2, 3, 4])
      ScheduleDay(
        weekday: dow,
        start: const Duration(hours: 8),
        end: const Duration(hours: 16),
      ),
  ],
);

HrReportInput input({String? employeeId}) => HrReportInput(
  period: HrReportPeriod(2026, 11),
  employees: [
    person('mona', 'Mona Ali'),
    // Created on Wednesday 4 Nov: no absences before that.
    person('omar', 'Omar Hassan', createdAt: cairo(4, 9)),
    person('gone', 'Former Employee', active: false),
  ],
  schedules: [schedule],
  days: {
    'mona': [
      // Sun: 08:00–18:30 → 10.5 h, 8 regular, 2.5 overtime.
      day('mona', 1, checkIn: cairo(1, 8), checkOut: cairo(1, 18, 30)),
      // Mon: late, left at 15:00 → 6.5 h, 60 min early.
      day(
        'mona',
        2,
        checkIn: cairo(2, 8, 30),
        checkOut: cairo(2, 15),
        late: 15,
      ),
      // Tue: closed automatically, a correction is pending.
      day('mona', 3, checkIn: cairo(3, 8), autoClosed: true),
      // Wed: closed automatically, corrected to 08:00–16:00.
      day(
        'mona',
        4,
        checkIn: cairo(4, 8),
        autoClosed: true,
        correctedIn: cairo(4, 8),
        correctedOut: cairo(4, 16),
      ),
      // Thu 5 Nov: no record → absence.
    ],
    'omar': [
      // Thu: in at 10:00, out 19:00 → 9 h: overtime starts after 8 worked
      // hours (18:00), not at the 16:00 shift end.
      day('omar', 5, checkIn: cairo(5, 10), checkOut: cairo(5, 19), late: 120),
    ],
  },
  corrections: [
    correction('mona-3', CorrectionStatus.pending),
    correction('mona-3', CorrectionStatus.rejected),
  ],
  generatedAt: generatedAt,
  generatedBy: 'Test Admin',
  employeeId: employeeId,
);

void main() {
  const builder = HrReportBuilder(localWallTime);

  group('HrReportPeriod', () {
    test('month bounds, navigation and file name', () {
      final november = HrReportPeriod(2026, 11);
      expect(november.first, DateTime(2026, 11));
      expect(november.last, DateTime(2026, 11, 30));
      expect(november.days.length, 30);
      expect(november.previous, HrReportPeriod(2026, 10));
      expect(HrReportPeriod(2026, 12).next, HrReportPeriod(2027, 1));
      expect(HrReportPeriod(2026, 1).previous, HrReportPeriod(2025, 12));
      expect(november.fileName, 'Attendance_Report_2026_11.xlsx');
    });
  });

  group('HrReportBuilder', () {
    final report = builder.build(input());
    SummaryRow summaryOf(String id) =>
        report.summary.singleWhere((row) => row.employee.id == id);
    DailyRow dayOf(String id, int date) => report.daily.singleWhere(
      (row) => row.employee.id == id && row.date == DateTime(2026, 11, date),
    );

    test('inactive accounts without records are left out', () {
      expect(report.summary.map((r) => r.employee.id), ['mona', 'omar']);
    });

    test('month totals for an employee', () {
      final mona = summaryOf('mona');
      expect(mona.workingDays, 22); // Sun–Thu in November 2026
      expect(mona.daysOff, 8);
      expect(mona.scheduledHours, const Duration(hours: 176));
      expect(mona.attendanceDays, 4);
      expect(mona.absenceDays, 1); // Thu 5 Nov; Fri 6 Nov is a day off
      expect(mona.lateDays, 1);
      expect(mona.earlyDays, 1);
      expect(mona.missingCheckOutDays, 1);
      // Only confirmed days: 10.5 + 6.5 + 8 (corrected); Tue counts nothing.
      expect(mona.verifiedHours, const Duration(hours: 25));
      expect(mona.regularHours, const Duration(hours: 22, minutes: 30));
      expect(mona.overtimeHours, const Duration(hours: 2, minutes: 30));
      expect(mona.unverifiedDays, 1);
      expect(mona.pendingReviews, 1);
      expect(mona.completion, 0.8); // 4 of 5 elapsed working days
    });

    test('overtime starts after 8 worked hours, not at the shift end', () {
      final omar = dayOf('omar', 5);
      expect(omar.worked, const Duration(hours: 9));
      expect(omar.regular, const Duration(hours: 8));
      expect(omar.overtime, const Duration(hours: 1));
      expect(omar.checkIn, DateTime(2026, 11, 5, 10)); // Cairo wall time
      expect(omar.checkOut, DateTime(2026, 11, 5, 19));
    });

    test('no absences before the account existed', () {
      final omar = summaryOf('omar');
      expect(omar.absenceDays, 1); // Wed 4 Nov only
      expect(dayOf('omar', 4).status, DayStatus.absent);
      expect(
        report.daily.where((r) => r.employee.id == 'omar' && r.date.day < 4),
        isEmpty,
      );
    });

    test('days are never assumed: statuses and approvals', () {
      expect(dayOf('mona', 1).status, DayStatus.completed);
      expect(dayOf('mona', 1).approval, ApprovalStatus.verified);

      final missing = dayOf('mona', 3);
      expect(missing.status, DayStatus.needsReview);
      expect(missing.worked, isNull);
      expect(missing.checkOut, isNull);
      expect(missing.approval, ApprovalStatus.correctionPending);
      expect(missing.notes.join(' '), contains('rejected'));

      final corrected = dayOf('mona', 4);
      expect(corrected.status, DayStatus.corrected);
      expect(corrected.approval, ApprovalStatus.correctionApproved);
      expect(corrected.worked, const Duration(hours: 8));
      expect(corrected.notes.join(' '), contains('08:00–16:00'));

      final absent = dayOf('mona', 5);
      expect(absent.status, DayStatus.absent);
      expect(absent.notes.single, contains('Leave is not recorded'));
    });

    test('future working days are not absences', () {
      expect(
        report.daily.where((row) => row.date.isAfter(DateTime(2026, 11, 6))),
        isEmpty,
      );
    });

    test('exceptions, most important first', () {
      expect(report.exceptions.first.type, 'Missing check-out');
      expect(report.exceptions.first.severity, ExceptionSeverity.high);
      expect(
        report.exceptions.map((e) => e.type),
        containsAll(['Absence', 'Missing check-out']),
      );
    });

    test('company totals', () {
      expect(report.employeeCount, 2);
      expect(report.attendanceDays, 5);
      expect(report.absenceDays, 2);
      expect(report.overtime, const Duration(hours: 3, minutes: 30));
      expect(report.pendingCorrections, 1);
      expect(report.pendingReviews, 1);
      expect(report.overtimeDays.length, 2);
    });

    test('one employee only', () {
      final single = builder.build(input(employeeId: 'omar'));
      expect(single.summary.single.employee.id, 'omar');
      expect(single.daily.every((row) => row.employee.id == 'omar'), isTrue);
    });
  });

  group('HR workbook', () {
    final report = builder.build(input());
    final bytes = HrWorkbook.encode(report);
    final archive = ZipDecoder().decodeBytes(bytes);
    String part(String name) =>
        utf8.decode(archive.findFile(name)!.readBytes()!);

    test('is a valid package with six named sheets', () {
      for (final name in [
        '[Content_Types].xml',
        '_rels/.rels',
        'xl/workbook.xml',
        'xl/styles.xml',
        'xl/_rels/workbook.xml.rels',
      ]) {
        expect(archive.findFile(name), isNotNull, reason: name);
      }
      final workbook = part('xl/workbook.xml');
      for (final name in [
        'Monthly HR Summary',
        'Daily Attendance',
        'Leave &amp; Absence',
        'Overtime',
        'Exceptions &amp; HR Review',
        'Report Information',
      ]) {
        expect(workbook, contains('name="$name"'));
      }
      expect(workbook, contains('_xlnm.Print_Titles'));
      for (var i = 1; i <= 6; i++) {
        expect(archive.findFile('xl/worksheets/sheet$i.xml'), isNotNull);
      }
    });

    test('frozen headers, filters, numbers and no formulas', () {
      final summary = part('xl/worksheets/sheet1.xml');
      expect(summary, contains('state="frozen"'));
      expect(summary, contains('topLeftCell="A5"'));
      expect(summary, contains('<autoFilter ref="A4:U'));
      // Numeric cells, not text: Mona's 25 confirmed hours.
      expect(summary, contains('<v>25.0</v>'));
      final daily = part('xl/worksheets/sheet2.xml');
      // 1 Nov 2026 as an Excel date serial.
      expect(daily, contains('<v>46327.0</v>'));
      for (var i = 1; i <= 6; i++) {
        expect(part('xl/worksheets/sheet$i.xml'), isNot(contains('<f>')));
      }
    });

    test('Arabic names survive and formula-like text is not a formula', () {
      final arabic = HrReportInput(
        period: HrReportPeriod(2026, 11),
        employees: [
          person('mona', 'منى علي'),
          person('omar', '=HYPERLINK("http://x","y")'),
        ],
        schedules: [schedule],
        days: const {},
        corrections: const [],
        generatedAt: generatedAt,
        generatedBy: 'مدير',
      );
      final book = ZipDecoder().decodeBytes(
        HrWorkbook.encode(builder.build(arabic)),
      );
      final summary = utf8.decode(
        book.findFile('xl/worksheets/sheet1.xml')!.readBytes()!,
      );
      expect(summary, contains('منى علي'));
      expect(
        summary,
        contains(
          's="${XlsxStyle.textQuoted.index}" t="inlineStr"><is><t xml:space="preserve">=HYPERLINK(&quot;',
        ),
      );
      expect(summary, isNot(contains('<f>')));
    });

    test('Excel date serials', () {
      expect(XlsxWorkbook.excelSerial(DateTime(2026, 1, 1)), 46023);
      expect(XlsxWorkbook.excelSerial(DateTime(1900, 3, 1)), 61);
      expect(XlsxWorkbook.excelSerial(DateTime(2026, 1, 1, 12)), 46023.5);
    });

    test('rejects invalid sheet names', () {
      final book = XlsxWorkbook(title: 't', creator: 'c')
        ..sheets.add(XlsxSheet(name: 'a/b', widths: const [10]));
      expect(book.encode, throwsArgumentError);
    });

    test('writes a file for a manual look in Excel', () {
      // Kept in the system temp folder for a manual look; not asserted.
      final file = File('${Directory.systemTemp.path}/hr_report_test.xlsx')
        ..writeAsBytesSync(bytes);
      expect(file.lengthSync(), greaterThan(1000));
    });
  });
}
