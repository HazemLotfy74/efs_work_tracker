import '../../admin/domain/entities/employee_entity.dart';
import '../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../attendance_session/domain/entities/attendance_session_entity.dart';
import 'entities/hr_report.dart';

/// Converts an exact instant to the wall-clock time of an IANA timezone.
typedef LocalTime = DateTime Function(DateTime instant, String timezone);

/// Calculates every sheet of the HR report from one [HrReportInput].
///
/// All hours come from [AttendanceSessionEntity] (the same rules as the app
/// screens): hours count only when confirmed, 8 h a day are regular and the
/// rest is overtime ([WorkDuration]). Nothing is assumed: a day without a
/// record is an absence only once it has passed, leave and holidays are not
/// recorded in the system, and overtime is calculated, never approved.
class HrReportBuilder {
  const HrReportBuilder(this._localTime);

  final LocalTime _localTime;

  /// A confirmed day longer than this is flagged for review.
  static const longDay = Duration(hours: 12);

  /// A confirmed day shorter than this is flagged for review.
  static const shortDay = Duration(hours: 1);

  HrReport build(HrReportInput input) {
    final schedules = {for (final s in input.schedules) s.id: s};
    final correctionsByDay = <String, List<CorrectionRequestEntity>>{};
    for (final correction in input.corrections) {
      correctionsByDay
          .putIfAbsent(correction.attendanceId, () => [])
          .add(correction);
    }

    final summary = <SummaryRow>[];
    final daily = <DailyRow>[];
    final exceptions = <ExceptionRow>[];

    final employees =
        [
          for (final employee in input.employees)
            if (input.employeeId == null || employee.id == input.employeeId)
              if (employee.isActive ||
                  (input.days[employee.id]?.isNotEmpty ?? false))
                employee,
        ]..sort(
          (a, b) =>
              a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );

    for (final employee in employees) {
      final schedule = schedules[employee.scheduleId];
      final sessions = {
        for (final day
            in input.days[employee.id] ?? const <AttendanceSessionEntity>[])
          if (day.workDate case final date?) _date(date): day,
      };
      final zone = schedule?.timezone ?? sessions.values.firstOrNull?.timezone;
      final today = zone == null
          ? _date(input.generatedAt)
          : _date(_localTime(input.generatedAt, zone));
      final created = employee.createdAt == null || zone == null
          ? null
          : _date(_localTime(employee.createdAt!, zone));

      var workingDays = 0, elapsed = 0, attended = 0, absent = 0;
      var late = 0, early = 0, missing = 0, unverified = 0, reviews = 0;
      var scheduled = Duration.zero, verified = Duration.zero;
      var regular = Duration.zero, overtime = Duration.zero;

      for (final date in input.period.days) {
        final shift = schedule?.dayFor(date);
        final session = sessions[date];
        if (shift != null) {
          workingDays++;
          scheduled += shift.length;
        }

        if (session != null) {
          final row = _dayRow(
            employee,
            date,
            session,
            schedule?.name ?? '',
            correctionsByDay[session.id] ?? const [],
            input.generatedAt,
          );
          daily.add(row);
          exceptions.addAll(_exceptions(row));
          attended++;
          elapsed++;
          if (row.lateMinutes > 0) late++;
          if (row.earlyMinutes > 0) early++;
          if (row.status == DayStatus.needsReview) missing++;
          if (!row.status.isVerified) unverified++;
          if (row.status == DayStatus.needsReview ||
              row.approval == ApprovalStatus.correctionPending) {
            reviews++;
          }
          verified += row.worked ?? Duration.zero;
          regular += row.regular ?? Duration.zero;
          overtime += row.overtime ?? Duration.zero;
          continue;
        }

        // No record: an absence only on a passed working day of an active
        // account that existed then. Leave is not recorded in the system,
        // so an absence may still be approved leave.
        final counts =
            shift != null &&
            employee.isActive &&
            date.isBefore(today) &&
            (created == null || !date.isBefore(created));
        if (!counts) continue;
        elapsed++;
        absent++;
        final row = DailyRow(
          employee: employee,
          date: date,
          scheduleName: schedule!.name,
          scheduledStart: date.add(shift.start),
          scheduledEnd: date.add(shift.end),
          status: DayStatus.absent,
          approval: ApprovalStatus.notApplicable,
          notes: const [
            'No check-in recorded. Leave is not recorded in the system.',
          ],
        );
        daily.add(row);
        exceptions.add(
          ExceptionRow(
            employee: employee,
            date: date,
            type: 'Absence',
            detail:
                'Scheduled working day without an attendance record. '
                'Confirm whether it was leave.',
            severity: ExceptionSeverity.medium,
          ),
        );
      }

      summary.add(
        SummaryRow(
          employee: employee,
          scheduleName: schedule?.name ?? '',
          workingDays: workingDays,
          daysOff: input.period.days.length - workingDays,
          attendanceDays: attended,
          absenceDays: absent,
          lateDays: late,
          earlyDays: early,
          missingCheckOutDays: missing,
          scheduledHours: scheduled,
          verifiedHours: verified,
          regularHours: regular,
          overtimeHours: overtime,
          unverifiedDays: unverified,
          pendingReviews: reviews,
          elapsedWorkingDays: elapsed,
        ),
      );
    }

    daily.sort((a, b) {
      final byName = a.employee.fullName.toLowerCase().compareTo(
        b.employee.fullName.toLowerCase(),
      );
      return byName != 0 ? byName : a.date.compareTo(b.date);
    });
    exceptions.sort((a, b) {
      final bySeverity = a.severity.index.compareTo(b.severity.index);
      return bySeverity != 0 ? bySeverity : a.date.compareTo(b.date);
    });
    return HrReport(
      input: input,
      summary: summary,
      daily: daily,
      exceptions: exceptions,
    );
  }

  DailyRow _dayRow(
    EmployeeEntity employee,
    DateTime date,
    AttendanceSessionEntity session,
    String scheduleName,
    List<CorrectionRequestEntity> corrections,
    DateTime now,
  ) {
    final zone = session.timezone;
    DateTime? local(DateTime? instant) => instant == null
        ? null
        : zone == null
        ? instant.toLocal()
        : _localTime(instant, zone);

    final pending = corrections.any(
      (c) => c.status == CorrectionStatus.pending,
    );
    final rejected = corrections.where(
      (c) => c.status == CorrectionStatus.rejected,
    );
    final base = session.statusAt(now);
    final status = switch (base) {
      AttendanceDayStatus.inProgress => DayStatus.inProgress,
      AttendanceDayStatus.needsReview => DayStatus.needsReview,
      AttendanceDayStatus.completed =>
        session.hasCorrection ? DayStatus.corrected : DayStatus.completed,
    };
    final approval = pending
        ? ApprovalStatus.correctionPending
        : switch (status) {
            DayStatus.corrected => ApprovalStatus.correctionApproved,
            DayStatus.completed => ApprovalStatus.verified,
            DayStatus.needsReview => ApprovalStatus.notVerified,
            DayStatus.inProgress ||
            DayStatus.absent => ApprovalStatus.notApplicable,
          };

    final duration = session.verifiedDuration;
    final notes = <String>[
      if (session.isAutoClosed && session.checkOut == null)
        'Closed automatically at the deadline; no check-out recorded.',
      if (session.hasCorrection)
        'Times corrected to ${_hm(local(session.effectiveCheckIn))}'
            '–${_hm(local(session.effectiveCheckOut))}.',
      if (pending) 'A correction request is waiting for review.',
      if (rejected.isNotEmpty)
        '${rejected.length} correction request(s) rejected.',
    ];

    return DailyRow(
      employee: employee,
      date: date,
      scheduleName: scheduleName,
      scheduledStart: date.add(session.shift.start),
      scheduledEnd: date.add(session.shift.end),
      checkIn: local(session.checkInTime),
      checkOut: local(session.checkOutTime),
      worked: duration?.worked,
      regular: duration?.regular,
      overtime: duration?.overtime,
      lateMinutes: session.lateMinutes,
      earlyMinutes: session.leftEarlyBy.inMinutes,
      status: status,
      approval: approval,
      notes: notes,
    );
  }

  Iterable<ExceptionRow> _exceptions(DailyRow row) sync* {
    ExceptionRow exception(String type, String detail, ExceptionSeverity s) =>
        ExceptionRow(
          employee: row.employee,
          date: row.date,
          type: type,
          detail: detail,
          severity: s,
        );

    if (row.status == DayStatus.needsReview) {
      yield exception(
        'Missing check-out',
        'Closed automatically; the hours are not confirmed and are not '
            'counted.${row.approval == ApprovalStatus.correctionPending ? ' A correction is pending.' : ''}',
        ExceptionSeverity.high,
      );
    } else if (row.approval == ApprovalStatus.correctionPending) {
      yield exception(
        'Correction pending',
        'A correction request for this day is waiting for review.',
        ExceptionSeverity.medium,
      );
    }
    final worked = row.worked;
    if (worked != null && worked > longDay) {
      yield exception(
        'Unusually long day',
        'More than ${longDay.inHours} confirmed hours.',
        ExceptionSeverity.medium,
      );
    }
    if (worked != null && worked < shortDay) {
      yield exception(
        'Very short day',
        'Less than ${shortDay.inHours} confirmed hour.',
        ExceptionSeverity.low,
      );
    }
  }

  static DateTime _date(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _hm(DateTime? time) => time == null
      ? '—'
      : '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}';
}
