import 'dart:async';

import 'package:efs_work_tracker/app/features/admin/domain/entities/admin_request_entity.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/employee_entity.dart';
import 'package:efs_work_tracker/app/features/admin/domain/repositories/admin_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/core/errors/admin_errors.dart';
import 'package:efs_work_tracker/core/manager/locale_cubit.dart';

/// In-memory [AdminRepository] for tests. Set [failure] to make calls fail.
class FakeAdminRepository implements AdminRepository {
  List<EmployeeEntity> employees = [];
  List<WorkScheduleOption> schedules = [];
  Map<String, AttendanceSessionEntity> today = {};
  Map<String, List<AttendanceSessionEntity>> history = {};
  List<AdminRequestEntity> requests = [];
  AdminFailure? failure;
  Completer<void>? gate;

  final created = <(NewEmployeeDraft, String)>[];
  final reviews = <(String, bool, String?)>[];

  void _fail() {
    if (failure case final failure?) throw failure;
  }

  @override
  Future<List<EmployeeEntity>> getEmployees() async {
    _fail();
    return employees;
  }

  @override
  Future<List<WorkScheduleOption>> getSchedules() async {
    _fail();
    return schedules;
  }

  @override
  Future<Map<String, AttendanceSessionEntity>> getToday(
    List<EmployeeEntity> employees,
    List<WorkScheduleOption> schedules,
  ) async {
    _fail();
    return today;
  }

  @override
  Future<List<AttendanceSessionEntity>> getHistory(
    String employeeId, {
    int limit = 60,
  }) async {
    _fail();
    return history[employeeId] ?? const [];
  }

  @override
  Future<String> createEmployee(
    NewEmployeeDraft draft, {
    required String requestId,
  }) async {
    await gate?.future;
    created.add((draft, requestId));
    _fail();
    return 'new-employee';
  }

  @override
  Future<List<AdminRequestEntity>> getPendingRequests() async {
    _fail();
    return requests;
  }

  @override
  Future<void> review(
    AdminRequestEntity request, {
    required bool approve,
    String? note,
  }) async {
    await gate?.future;
    _fail();
    reviews.add((request.id, approve, note));
    requests = [
      for (final r in requests)
        if (r.id != request.id) r,
    ];
  }
}

/// A [LocaleStore] that forgets everything when the test ends.
class MemoryLocaleStore implements LocaleStore {
  MemoryLocaleStore([this.saved]);

  String? saved;

  @override
  Future<String?> read() async => saved;

  @override
  Future<void> write(String languageCode) async => saved = languageCode;
}
