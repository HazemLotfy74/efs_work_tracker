part of 'employee_details_cubit.dart';

sealed class EmployeeDetailsState {
  const EmployeeDetailsState();
}

final class EmployeeDetailsLoading extends EmployeeDetailsState {
  const EmployeeDetailsLoading();
}

final class EmployeeDetailsNotFound extends EmployeeDetailsState {
  const EmployeeDetailsNotFound();
}

final class EmployeeDetailsError extends EmployeeDetailsState {
  const EmployeeDetailsError();
}

final class EmployeeDetailsLoaded extends EmployeeDetailsState {
  const EmployeeDetailsLoaded({
    required this.employee,
    required this.schedules,
    required this.days,
    required this.corrections,
    this.range,
    this.busy = false,
  });

  final EmployeeEntity employee;
  final List<WorkScheduleOption> schedules;

  /// Every loaded day, newest first.
  final List<AttendanceSessionEntity> days;

  /// The employee's correction requests, newest first.
  final List<CorrectionRequestEntity> corrections;

  /// The selected work dates; `null` for all loaded days.
  final WorkDateRange? range;

  /// An admin action is being sent.
  final bool busy;

  WorkScheduleOption? get schedule =>
      schedules.where((s) => s.id == employee.scheduleId).firstOrNull;

  /// The days in [range], newest first.
  List<AttendanceSessionEntity> get visibleDays {
    final range = this.range;
    if (range == null) return days;
    return [
      for (final day in days)
        if (range.contains(day.workDate ?? day.checkInTime)) day,
    ];
  }

  /// The latest correction request for each attendance day.
  Map<String, CorrectionRequestEntity> get latestCorrection => {
    for (final request in corrections.reversed) request.attendanceId: request,
  };

  EmployeeDetailsLoaded copyWith({
    WorkDateRange? Function()? range,
    bool? busy,
  }) => EmployeeDetailsLoaded(
    employee: employee,
    schedules: schedules,
    days: days,
    corrections: corrections,
    range: range == null ? this.range : range(),
    busy: busy ?? this.busy,
  );
}
