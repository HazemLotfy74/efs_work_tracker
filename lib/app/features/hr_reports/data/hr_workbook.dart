import 'dart:typed_data';

import '../domain/entities/hr_report.dart';
import 'xlsx/xlsx_writer.dart';

/// Turns an [HrReport] into the HR workbook (six sheets). Layout only: every
/// number comes from the report, nothing is recalculated here.
///
/// Each sheet: title (row 1), period (row 2), blank row, headers (row 4,
/// frozen, filtered, repeated when printed), data. Hours are decimal numbers
/// (7.5 = 7 h 30 min), dates and times real Excel values.
abstract final class HrWorkbook {
  static const company = 'Facilities Services Misr (EFS)';

  /// The policy version printed on the information sheet.
  static const policy =
      '8 confirmed hours a day are regular, the rest is overtime (calculated, '
      'not approved). Days closed automatically count no hours until corrected.';

  static Uint8List encode(HrReport report) {
    final book = XlsxWorkbook(
      title: 'Attendance & Payroll Report ${_period(report.input.period)}',
      creator: 'EFS WorkTrack',
      created: report.input.generatedAt,
    );
    book.sheets.addAll([
      _summary(report),
      _daily(report),
      _leave(report),
      _overtime(report),
      _exceptions(report),
      _info(report),
    ]);
    return book.encode();
  }

  static XlsxSheet _summary(HrReport report) {
    final sheet = _start(report, 'Monthly HR Summary', const [
      ('Employee ID', 12),
      ('Employee name', 26),
      ('Schedule', 16),
      ('Role', 10),
      ('Month', 10),
      ('Official working days', 11),
      ('Weekly days off', 10),
      ('Approved holidays', 10),
      ('Approved leave days', 10),
      ('Attendance days', 11),
      ('Absence days (no record)', 11),
      ('Late arrival days', 10),
      ('Early departure days', 10),
      ('Missing check-out days', 11),
      ('Scheduled hours', 11),
      ('Confirmed working hours', 12),
      ('Regular hours', 11),
      ('Calculated overtime hours (not approved)', 14),
      ('Days with unconfirmed hours', 12),
      ('Pending HR reviews', 11),
      ('Attendance completion', 12),
    ]);
    final month = _period(report.input.period);
    for (final row in report.summary) {
      sheet.add([
        _text(row.employee.employeeCode),
        _text(row.employee.fullName),
        _text(row.scheduleName),
        _text(row.employee.isAdmin ? 'Admin' : 'Employee'),
        _text(month),
        _int(row.workingDays),
        _int(row.daysOff),
        // Holidays and leave are not recorded in the system (see the
        // information sheet); left empty instead of a misleading zero.
        const XlsxCell(null),
        const XlsxCell(null),
        _int(row.attendanceDays),
        _int(row.absenceDays, row.absenceDays > 0 ? XlsxStyle.warning : null),
        _int(row.lateDays),
        _int(row.earlyDays),
        _int(
          row.missingCheckOutDays,
          row.missingCheckOutDays > 0 ? XlsxStyle.bad : null,
        ),
        _hours(row.scheduledHours),
        _hours(row.verifiedHours),
        _hours(row.regularHours),
        _hours(row.overtimeHours),
        _int(row.unverifiedDays),
        _int(
          row.pendingReviews,
          row.pendingReviews > 0 ? XlsxStyle.warning : null,
        ),
        XlsxCell(row.completion, XlsxStyle.percent),
      ]);
    }
    Duration sum(Duration Function(SummaryRow row) of) =>
        report.summary.fold(Duration.zero, (total, row) => total + of(row));
    int count(int Function(SummaryRow row) of) =>
        report.summary.fold(0, (total, row) => total + of(row));
    sheet.add([
      const XlsxCell('Total', XlsxStyle.totalLabel),
      XlsxCell('${report.summary.length} employees', XlsxStyle.totalLabel),
      const XlsxCell(null, XlsxStyle.totalLabel),
      const XlsxCell(null, XlsxStyle.totalLabel),
      const XlsxCell(null, XlsxStyle.totalLabel),
      _totalInt(count((r) => r.workingDays)),
      _totalInt(count((r) => r.daysOff)),
      const XlsxCell(null, XlsxStyle.totalLabel),
      const XlsxCell(null, XlsxStyle.totalLabel),
      _totalInt(count((r) => r.attendanceDays)),
      _totalInt(count((r) => r.absenceDays)),
      _totalInt(count((r) => r.lateDays)),
      _totalInt(count((r) => r.earlyDays)),
      _totalInt(count((r) => r.missingCheckOutDays)),
      _totalHours(sum((r) => r.scheduledHours)),
      _totalHours(sum((r) => r.verifiedHours)),
      _totalHours(sum((r) => r.regularHours)),
      _totalHours(sum((r) => r.overtimeHours)),
      _totalInt(count((r) => r.unverifiedDays)),
      _totalInt(count((r) => r.pendingReviews)),
      const XlsxCell(null, XlsxStyle.totalLabel),
    ]);
    return sheet;
  }

  static XlsxSheet _daily(HrReport report) {
    final sheet = _start(report, 'Daily Attendance', const [
      ('Employee ID', 12),
      ('Employee name', 24),
      ('Date', 11),
      ('Day', 10),
      ('Schedule', 14),
      ('Scheduled check-in', 10),
      ('Scheduled check-out', 10),
      ('Actual check-in', 10),
      ('Actual check-out', 10),
      ('Confirmed hours', 10),
      ('Regular hours', 10),
      ('Overtime hours', 10),
      ('Late (min)', 9),
      ('Early departure (min)', 10),
      ('Attendance status', 26),
      ('Approval status', 18),
      ('Notes', 48),
    ]);
    for (final row in report.daily) {
      sheet.add([
        _text(row.employee.employeeCode),
        _text(row.employee.fullName),
        XlsxCell(row.date, XlsxStyle.date),
        _text(_weekday(row.date)),
        _text(row.scheduleName),
        XlsxCell(row.scheduledStart, XlsxStyle.time),
        XlsxCell(row.scheduledEnd, XlsxStyle.time),
        XlsxCell(row.checkIn, XlsxStyle.time),
        XlsxCell(row.checkOut, XlsxStyle.time),
        _maybeHours(row.worked),
        _maybeHours(row.regular),
        _maybeHours(row.overtime),
        _int(row.lateMinutes, row.lateMinutes > 0 ? XlsxStyle.warning : null),
        _int(row.earlyMinutes, row.earlyMinutes > 0 ? XlsxStyle.warning : null),
        XlsxCell(row.status.label, _statusStyle(row.status)),
        _text(row.approval.label),
        XlsxCell(row.notes.join(' '), XlsxStyle.wrap),
      ]);
    }
    return sheet;
  }

  static XlsxSheet _leave(HrReport report) {
    final sheet = _start(report, 'Leave & Absence', const [
      ('Employee ID', 12),
      ('Employee name', 24),
      ('Date', 11),
      ('Day', 10),
      ('Type', 22),
      ('Duration (days)', 10),
      ('Approval status', 22),
      ('Notes', 60),
    ]);
    for (final row in report.absences) {
      sheet.add([
        _text(row.employee.employeeCode),
        _text(row.employee.fullName),
        XlsxCell(row.date, XlsxStyle.date),
        _text(_weekday(row.date)),
        const XlsxCell('Absence (no record)', XlsxStyle.warning),
        _int(1),
        _text('Unconfirmed'),
        const XlsxCell(
          'No check-in on a scheduled working day. Leave is not recorded in '
          'the system: confirm whether this was approved leave.',
          XlsxStyle.wrap,
        ),
      ]);
    }
    if (report.absences.isEmpty) {
      sheet.add([
        const XlsxCell('No absences in this period.', XlsxStyle.subtitle),
      ]);
    }
    return sheet;
  }

  static XlsxSheet _overtime(HrReport report) {
    final sheet = _start(report, 'Overtime', const [
      ('Employee ID', 12),
      ('Employee name', 24),
      ('Date', 11),
      ('Day', 10),
      ('Confirmed hours', 10),
      ('Regular hours', 10),
      ('Calculated overtime', 11),
      ('Approved overtime', 11),
      ('Approval status', 26),
    ]);
    for (final row in report.overtimeDays) {
      sheet.add([
        _text(row.employee.employeeCode),
        _text(row.employee.fullName),
        XlsxCell(row.date, XlsxStyle.date),
        _text(_weekday(row.date)),
        _maybeHours(row.worked),
        _maybeHours(row.regular),
        _maybeHours(row.overtime),
        const XlsxCell(null),
        const XlsxCell('Not approved — no approval process', XlsxStyle.warning),
      ]);
    }
    if (report.overtimeDays.isEmpty) {
      sheet.add([
        const XlsxCell('No overtime in this period.', XlsxStyle.subtitle),
      ]);
    }
    return sheet;
  }

  static XlsxSheet _exceptions(HrReport report) {
    final sheet = _start(report, 'Exceptions & HR Review', const [
      ('Priority', 10),
      ('Employee ID', 12),
      ('Employee name', 24),
      ('Date', 11),
      ('Issue', 22),
      ('Details', 70),
    ]);
    for (final row in report.exceptions) {
      sheet.add([
        switch (row.severity) {
          ExceptionSeverity.high => const XlsxCell('High', XlsxStyle.bad),
          ExceptionSeverity.medium => const XlsxCell(
            'Medium',
            XlsxStyle.warning,
          ),
          ExceptionSeverity.low => const XlsxCell('Low', XlsxStyle.text),
        },
        _text(row.employee.employeeCode),
        _text(row.employee.fullName),
        XlsxCell(row.date, XlsxStyle.date),
        _text(row.type),
        XlsxCell(row.detail, XlsxStyle.wrap),
      ]);
    }
    if (report.exceptions.isEmpty) {
      sheet.add([
        const XlsxCell(
          'Nothing needs review in this period.',
          XlsxStyle.subtitle,
        ),
      ]);
    }
    return sheet;
  }

  static XlsxSheet _info(HrReport report) {
    final input = report.input;
    final sheet =
        XlsxSheet(
            name: 'Report Information',
            widths: const [30, 90],
            landscape: false,
          )
          ..add([const XlsxCell('Report information', XlsxStyle.title)])
          ..add([XlsxCell(company, XlsxStyle.subtitle)])
          ..add(const []);
    void line(
      String label,
      Object? value, [
      XlsxStyle style = XlsxStyle.wrap,
    ]) => sheet.add([XlsxCell(label, XlsxStyle.label), XlsxCell(value, style)]);
    line('Company', company);
    line('Report', 'Attendance & Payroll Preparation Report');
    line(
      'Reporting period',
      '${_ymd(input.period.first)} to ${_ymd(input.period.last)}',
    );
    line('Generated at', input.generatedAt.toLocal(), XlsxStyle.date);
    line('Generated at (time)', input.generatedAt.toLocal(), XlsxStyle.time);
    line('Generated by', input.generatedBy);
    line('Employees', report.employeeCount, XlsxStyle.integer);
    line(
      'Filter',
      input.employeeId == null
          ? 'All employees'
          : 'One employee: ${report.summary.firstOrNull?.employee.fullName ?? ''}',
    );
    line('Attendance policy', policy);
    line(
      'Source',
      'Live attendance records (Supabase), read at generation time.',
    );
    line('Status', 'Generated');
    sheet.add(const []);
    sheet.add([const XlsxCell('Not available in the system', XlsxStyle.title)]);
    for (final (label, detail) in const [
      (
        'Leave',
        'Leave is not recorded. Absences are scheduled working days without a '
            'check-in; any of them may be approved leave.',
      ),
      ('Public holidays', 'Not recorded; counted as working days.'),
      (
        'Overtime approval',
        'Overtime is calculated (beyond 8 confirmed hours a day) but there is '
            'no approval step, so no overtime is marked approved or payable.',
      ),
      (
        'Payroll values',
        'No salaries, rates, deductions or taxes are calculated. Use the '
            'confirmed hours with your payroll policy.',
      ),
      ('Departments / job titles', 'Not recorded on employee profiles.'),
      (
        'Absence history',
        'Absences use each employee\'s current schedule and start from the '
            'account creation date; inactive accounts get no absences.',
      ),
    ]) {
      line(label, detail);
    }
    return sheet;
  }

  // Helpers.

  static XlsxSheet _start(
    HrReport report,
    String name,
    List<(String, double)> columns,
  ) {
    final sheet =
        XlsxSheet(
            name: name,
            widths: [for (final (_, width) in columns) width],
            headerRow: 3,
          )
          ..add([XlsxCell(name, XlsxStyle.title)])
          ..add([
            XlsxCell(
              '$company · ${_period(report.input.period)} · '
              'generated ${_ymd(report.input.generatedAt.toLocal())}',
              XlsxStyle.subtitle,
            ),
          ])
          ..add(const []);
    sheet.add([
      for (final (title, _) in columns) XlsxCell(title, XlsxStyle.header),
    ]);
    return sheet;
  }

  static XlsxCell _text(String value) => XlsxCell(value);

  static XlsxCell _int(int value, [XlsxStyle? style]) =>
      XlsxCell(value, style ?? XlsxStyle.integer);

  static XlsxCell _totalInt(int value) =>
      XlsxCell(value, XlsxStyle.totalInteger);

  static XlsxCell _hours(Duration value) =>
      XlsxCell(hoursOf(value), XlsxStyle.hours);

  static XlsxCell _maybeHours(Duration? value) =>
      XlsxCell(value == null ? null : hoursOf(value), XlsxStyle.hours);

  static XlsxCell _totalHours(Duration value) =>
      XlsxCell(hoursOf(value), XlsxStyle.totalHours);

  /// Decimal hours rounded to 2 places: 7 h 30 min → 7.5.
  static double hoursOf(Duration value) =>
      (value.inSeconds / 3600 * 100).round() / 100;

  static XlsxStyle _statusStyle(DayStatus status) => switch (status) {
    DayStatus.completed || DayStatus.corrected => XlsxStyle.good,
    DayStatus.inProgress => XlsxStyle.text,
    DayStatus.needsReview => XlsxStyle.bad,
    DayStatus.absent => XlsxStyle.warning,
  };

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String _weekday(DateTime date) => _weekdays[date.weekday - 1];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String _period(HrReportPeriod period) =>
      '${_months[period.month - 1]} ${period.year}';

  static String _ymd(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
