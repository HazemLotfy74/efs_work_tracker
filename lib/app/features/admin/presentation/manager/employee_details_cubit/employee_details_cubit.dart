import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/admin_errors.dart';
import '../../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../domain/entities/employee_attendance_stats.dart';
import '../../../domain/entities/employee_entity.dart';
import '../../../domain/repositories/admin_repository.dart';

part 'employee_details_state.dart';

/// One employee for an admin: profile, attendance days (filtered by a date
/// range), corrections, and the admin actions the database offers.
///
/// Opening it changes nothing: no record is marked as reviewed.
class EmployeeDetailsCubit extends Cubit<EmployeeDetailsState> {
  EmployeeDetailsCubit(this._repository, this.employeeId)
    : super(const EmployeeDetailsLoading());

  final AdminRepository _repository;
  final String employeeId;

  /// How many days are loaded: one record per day, so well over a year.
  /// The list itself loads no photos.
  static const historyLimit = 400;

  int _loadId = 0;

  Future<void> load() async {
    final loadId = ++_loadId;
    final previous = state;
    if (previous is! EmployeeDetailsLoaded) {
      emit(const EmployeeDetailsLoading());
    }
    try {
      final employee = await _repository.getEmployee(employeeId);
      if (employee == null) {
        if (!isClosed && loadId == _loadId) {
          emit(const EmployeeDetailsNotFound());
        }
        return;
      }
      final (schedules, days, corrections) = await (
        _repository.getSchedules(),
        _repository.getHistory(employeeId, limit: historyLimit),
        _repository.getCorrections(employeeId),
      ).wait;
      if (isClosed || loadId != _loadId) return;
      emit(
        EmployeeDetailsLoaded(
          employee: employee,
          schedules: schedules,
          days: days,
          corrections: corrections,
          range: previous is EmployeeDetailsLoaded ? previous.range : null,
        ),
      );
    } catch (_) {
      if (isClosed || loadId != _loadId) return;
      if (state is! EmployeeDetailsLoaded) emit(const EmployeeDetailsError());
    }
  }

  /// `null` shows every loaded day.
  void setRange(WorkDateRange? range) {
    final current = state;
    if (current is EmployeeDetailsLoaded) {
      emit(current.copyWith(range: () => range));
    }
  }

  Future<AdminFailure?> setActive(bool active) =>
      _act(() => _repository.setEmployeeActive(employeeId, active: active));

  /// Permanently deletes the account. On success the page is left as it is
  /// (still busy) for the screen to close: there is nothing to reload.
  /// On failure the employee is reloaded and stays on screen.
  Future<AdminFailure?> delete() async {
    final current = state;
    if (current is! EmployeeDetailsLoaded || current.busy) {
      return AdminFailure.busy;
    }
    emit(current.copyWith(busy: true));
    try {
      await _repository.deleteEmployee(employeeId);
      return null;
    } catch (error) {
      final failure = error is AdminFailure ? error : AdminFailure.unknown;
      if (isClosed) return failure;
      await load();
      final latest = state;
      if (latest is EmployeeDetailsLoaded) emit(latest.copyWith(busy: false));
      return failure;
    }
  }

  Future<AdminFailure?> assignSchedule(String scheduleId) =>
      _act(() => _repository.assignSchedule(employeeId, scheduleId));

  /// Runs one admin action, then reloads; returns why it failed.
  Future<AdminFailure?> _act(Future<void> Function() action) async {
    final current = state;
    if (current is! EmployeeDetailsLoaded || current.busy) {
      return AdminFailure.busy;
    }
    emit(current.copyWith(busy: true));
    AdminFailure? failure;
    try {
      await action();
    } catch (error) {
      failure = error is AdminFailure ? error : AdminFailure.unknown;
    }
    if (isClosed) return failure;
    await load();
    final latest = state;
    if (latest is EmployeeDetailsLoaded) emit(latest.copyWith(busy: false));
    return failure;
  }
}
