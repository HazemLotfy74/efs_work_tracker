import '../../../admin/domain/entities/employee_entity.dart';
import '../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';

/// A calendar month of work dates (date only, inclusive).
class HrReportPeriod {
  HrReportPeriod(this.year, this.month)
    : first = DateTime(year, month),
      last = DateTime(year, month + 1, 0);

  final int year;
  final int month;
  final DateTime first;
  final DateTime last;

  /// The month containing [date].
  factory HrReportPeriod.of(DateTime date) =>
      HrReportPeriod(date.year, date.month);

  HrReportPeriod get previous => HrReportPeriod.of(DateTime(year, month - 1));
  HrReportPeriod get next => HrReportPeriod.of(DateTime(year, month + 1));

  Iterable<DateTime> get days sync* {
    for (var day = first; !day.isAfter(last); day = _nextDay(day)) {
      yield day;
    }
  }

  /// `Attendance_Report_2026_11.xlsx`.
  String get fileName =>
      'Attendance_Report_${first.year}_${first.month.toString().padLeft(2, '0')}.xlsx';

  @override
  bool operator ==(Object other) =>
      other is HrReportPeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

DateTime _nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);

/// One `schedule_days` row: a weekday's shift, in the schedule's timezone.
class ScheduleDay {
  const ScheduleDay({
    required this.weekday,
    required this.start,
    required this.end,
  });

  /// PostgreSQL `dow`: 0 = Sunday … 6 = Saturday.
  final int weekday;

  /// From midnight, e.g. 8:00 → `Duration(hours: 8)`.
  final Duration start;
  final Duration end;

  Duration get length => end - start;
}

/// A work schedule with its weekly shifts.
class ReportSchedule {
  const ReportSchedule({
    required this.id,
    required this.name,
    required this.timezone,
    required this.days,
  });

  final String id;
  final String name;
  final String timezone;
  final List<ScheduleDay> days;

  ScheduleDay? dayFor(DateTime date) {
    final dow = date.weekday % 7;
    for (final day in days) {
      if (day.weekday == dow) return day;
    }
    return null;
  }
}

/// Everything the report is calculated from, as read from the database.
class HrReportInput {
  const HrReportInput({
    required this.period,
    required this.employees,
    required this.schedules,
    required this.days,
    required this.corrections,
    required this.generatedAt,
    required this.generatedBy,
    this.employeeId,
  });

  final HrReportPeriod period;
  final List<EmployeeEntity> employees;
  final List<ReportSchedule> schedules;

  /// Attendance days of the period, by employee id.
  final Map<String, List<AttendanceSessionEntity>> days;

  /// Correction requests about days of the period (any status).
  final List<CorrectionRequestEntity> corrections;
  final DateTime generatedAt;
  final String generatedBy;

  /// Only this employee; `null` for everyone.
  final String? employeeId;
}

/// The status of one employee-day, as the report states it.
enum DayStatus {
  completed('Completed'),
  corrected('Completed (corrected)'),
  inProgress('In progress'),
  needsReview('Missing check-out — HR review'),
  absent('Absent — no attendance record');

  const DayStatus(this.label);
  final String label;

  /// The hours of the day are confirmed (checked out or corrected).
  bool get isVerified => this == completed || this == corrected;
}

/// How far a day's hours are approved.
enum ApprovalStatus {
  verified('Verified'),
  correctionApproved('Correction approved'),
  correctionPending('Correction pending'),
  notVerified('Not verified'),
  notApplicable('—');

  const ApprovalStatus(this.label);
  final String label;
}

/// One row of the daily sheet: an employee on a date.
class DailyRow {
  const DailyRow({
    required this.employee,
    required this.date,
    required this.scheduleName,
    required this.status,
    required this.approval,
    this.scheduledStart,
    this.scheduledEnd,
    this.checkIn,
    this.checkOut,
    this.worked,
    this.regular,
    this.overtime,
    this.lateMinutes = 0,
    this.earlyMinutes = 0,
    this.notes = const [],
  });

  final EmployeeEntity employee;
  final DateTime date;
  final String scheduleName;

  /// Local wall-clock times in the schedule's timezone.
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? checkIn;
  final DateTime? checkOut;

  /// `null` when the hours are not confirmed.
  final Duration? worked;
  final Duration? regular;
  final Duration? overtime;
  final int lateMinutes;
  final int earlyMinutes;
  final DayStatus status;
  final ApprovalStatus approval;
  final List<String> notes;
}

/// Something HR has to look at.
class ExceptionRow {
  const ExceptionRow({
    required this.employee,
    required this.date,
    required this.type,
    required this.detail,
    required this.severity,
  });

  final EmployeeEntity employee;
  final DateTime date;
  final String type;
  final String detail;
  final ExceptionSeverity severity;
}

enum ExceptionSeverity { high, medium, low }

/// One employee's month.
class SummaryRow {
  const SummaryRow({
    required this.employee,
    required this.scheduleName,
    required this.workingDays,
    required this.daysOff,
    required this.attendanceDays,
    required this.absenceDays,
    required this.lateDays,
    required this.earlyDays,
    required this.missingCheckOutDays,
    required this.scheduledHours,
    required this.verifiedHours,
    required this.regularHours,
    required this.overtimeHours,
    required this.unverifiedDays,
    required this.pendingReviews,
    required this.elapsedWorkingDays,
  });

  final EmployeeEntity employee;
  final String scheduleName;

  /// Scheduled working days in the whole month (no holidays recorded).
  final int workingDays;
  final int daysOff;
  final int attendanceDays;

  /// Elapsed scheduled days without any attendance record.
  final int absenceDays;
  final int lateDays;
  final int earlyDays;
  final int missingCheckOutDays;
  final Duration scheduledHours;

  /// Confirmed hours only (checked out, or corrected).
  final Duration verifiedHours;
  final Duration regularHours;

  /// Calculated: beyond 8 confirmed hours a day. Not approved (there is no
  /// overtime approval in the system).
  final Duration overtimeHours;

  /// Days whose hours are not confirmed (missing check-out, in progress).
  final int unverifiedDays;

  /// Missing check-outs without a correction + pending corrections.
  final int pendingReviews;

  /// Scheduled working days up to the report date (for completion %).
  final int elapsedWorkingDays;

  /// Attendance days as a share of elapsed working days; `null` when none
  /// elapsed.
  double? get completion =>
      elapsedWorkingDays == 0 ? null : attendanceDays / elapsedWorkingDays;
}

/// The whole report: every sheet's rows from one set of data.
class HrReport {
  const HrReport({
    required this.input,
    required this.summary,
    required this.daily,
    required this.exceptions,
  });

  final HrReportInput input;
  final List<SummaryRow> summary;

  /// Every employee-day of the period with a record or an absence.
  final List<DailyRow> daily;
  final List<ExceptionRow> exceptions;

  Iterable<DailyRow> get absences =>
      daily.where((row) => row.status == DayStatus.absent);

  Iterable<DailyRow> get overtimeDays => daily.where(
    (row) => row.overtime != null && row.overtime! > Duration.zero,
  );

  int get employeeCount => summary.length;
  int get attendanceDays =>
      summary.fold(0, (sum, row) => sum + row.attendanceDays);
  int get absenceDays => summary.fold(0, (sum, row) => sum + row.absenceDays);
  int get lateDays => summary.fold(0, (sum, row) => sum + row.lateDays);
  Duration get overtime =>
      summary.fold(Duration.zero, (sum, row) => sum + row.overtimeHours);
  int get pendingReviews =>
      summary.fold(0, (sum, row) => sum + row.pendingReviews);
  int get pendingCorrections => input.corrections
      .where((c) => c.status == CorrectionStatus.pending)
      .length;
}
