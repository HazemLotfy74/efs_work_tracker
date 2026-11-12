import 'dart:async';

import 'package:efs_work_tracker/app/features/admin/domain/entities/admin_request_entity.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/audit_entry_entity.dart';
import 'package:efs_work_tracker/app/features/admin/domain/entities/employee_entity.dart';
import 'package:efs_work_tracker/app/features/admin/domain/repositories/admin_repository.dart';
import 'package:efs_work_tracker/app/features/attendance_correction/domain/entities/correction_request_entity.dart';
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

  /// Attendance days by record id, with whose they are.
  Map<String, EmployeeDay> days = {};
  List<CorrectionRequestEntity> corrections = [];
  List<AuditEntryEntity> audit = [];

  /// Fails only the selfie signing (the photo can't be shown).
  bool evidenceFails = false;
  final signed = <String>[];
  final activeChanges = <(String, bool)>[];
  final scheduleChanges = <(String, String)>[];

  @override
  Future<EmployeeEntity?> getEmployee(String id) async {
    _fail();
    return employees.where((e) => e.id == id).firstOrNull;
  }

  @override
  Future<EmployeeDay?> getDay(String attendanceId) async {
    _fail();
    return days[attendanceId];
  }

  @override
  Future<List<CorrectionRequestEntity>> getCorrections(
    String employeeId,
  ) async {
    _fail();
    return [
      for (final request in corrections)
        if (request.employeeId == employeeId) request,
    ];
  }

  @override
  Future<String> evidenceUrl(String selfiePath) async {
    _fail();
    if (evidenceFails) throw AdminFailure.notAllowed;
    signed.add(selfiePath);
    return 'https://storage.test/$selfiePath?token=t';
  }

  @override
  Future<void> setEmployeeActive(
    String employeeId, {
    required bool active,
  }) async {
    await gate?.future;
    _fail();
    activeChanges.add((employeeId, active));
    employees = [
      for (final e in employees)
        if (e.id == employeeId)
          EmployeeEntity(
            id: e.id,
            fullName: e.fullName,
            username: e.username,
            employeeCode: e.employeeCode,
            role: e.role,
            isActive: active,
            mustChangePassword: e.mustChangePassword,
            scheduleId: e.scheduleId,
            createdAt: e.createdAt,
          )
        else
          e,
    ];
  }

  final corrected = <(String, DateTime, DateTime, String)>[];

  @override
  Future<void> correctAttendance(
    String attendanceId, {
    required DateTime checkIn,
    required DateTime checkOut,
    required String reason,
  }) async {
    await gate?.future;
    _fail();
    corrected.add((attendanceId, checkIn, checkOut, reason));
  }

  @override
  Future<void> assignSchedule(String employeeId, String scheduleId) async {
    _fail();
    scheduleChanges.add((employeeId, scheduleId));
  }

  @override
  Future<List<AuditEntryEntity>> getAuditHistory(
    String employeeId, {
    int limit = 200,
  }) async {
    _fail();
    return audit;
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

  /// Everyone's recent days, newest first.
  List<EmployeeDay> recent = [];

  @override
  Future<List<EmployeeDay>> getRecentDays({int limit = 300}) async {
    _fail();
    return recent;
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

  final edits = <(String, String, String, String)>[];
  LoginEmail loginEmail = (
    email: 'employee@example.com',
    pendingEmail: null,
    expiresAt: null,
  );
  final emailRequests = <(String, String?)>[];
  final cashAssignments = <(String, String?)>[];

  @override
  Future<void> editEmployee(
    String employeeId, {
    required String fullName,
    required String username,
    required String employeeCode,
  }) async {
    await gate?.future;
    _fail();
    edits.add((employeeId, fullName, username, employeeCode));
  }

  @override
  Future<LoginEmail> getLoginEmail(String employeeId) async {
    _fail();
    return loginEmail;
  }

  @override
  Future<void> requestEmailChange(String employeeId, String? newEmail) async {
    _fail();
    emailRequests.add((employeeId, newEmail));
    loginEmail = (
      email: loginEmail.email,
      pendingEmail: newEmail,
      expiresAt: null,
    );
  }

  @override
  Future<void> assignCashReviewer(String requestId, String? reviewerId) async {
    _fail();
    cashAssignments.add((requestId, reviewerId));
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
