import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../../core/errors/admin_errors.dart';
import '../../../../../core/services/database_services.dart';
import '../../../admin/data/repositories/supabase_admin_repository.dart';
import '../../../admin/domain/entities/employee_entity.dart';
import '../../../admin/domain/repositories/admin_repository.dart';
import '../../../attendance_correction/data/models/correction_request_model.dart';
import '../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../attendance_session/data/models/attendance_session_model.dart';
import '../../../attendance_session/data/models/shift_model.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../domain/entities/hr_report.dart';
import '../../domain/repositories/hr_report_repository.dart';

/// The wall-clock time of [instant] in the IANA [timezone].
DateTime localWallTime(DateTime instant, String timezone) {
  final local = tz.TZDateTime.from(instant, ShiftModel.locationNamed(timezone));
  return DateTime(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
    local.second,
  );
}

/// [HrReportRepository] on the existing tables, read through the admin RLS
/// policies. A month is four requests, run together: employees, schedules
/// with their days, the month's attendance days, and correction requests.
class SupabaseHrReportRepository implements HrReportRepository {
  SupabaseHrReportRepository({
    required this._admin,
    required this._databaseServices,
    this._now = DateTime.now,
    this._folder = _defaultFolder,
    this._share = _shareFile,
    this.timeout = const Duration(seconds: 30),
  });

  final AdminRepository _admin;
  final DatabaseServices _databaseServices;
  final DateTime Function() _now;
  final Future<Directory> Function() _folder;
  final Future<void> Function(File file, String fileName) _share;
  final Duration timeout;

  static const _correctionColumns =
      'id, employee_id, attendance_id, proposed_checkin, proposed_checkout, '
      'reason, status, review_note, reviewed_at, created_at';

  @override
  Future<HrReportInput> load(
    HrReportPeriod period, {
    required String generatedBy,
    String? employeeId,
  }) async {
    final from = _ymd(period.first);
    final to = _ymd(period.last.add(const Duration(days: 1)));
    // Future.wait rethrows the first failure as it is (an AdminFailure).
    final results = await Future.wait<Object?>([
      _admin.getEmployees(),
      _read(
        'work_schedules',
        () => _databaseServices.getData(
          path: 'work_schedules',
          column:
              'id, name, timezone, schedule_days(weekday, starts_at, ends_at)',
          orderBy: 'name',
        ),
      ),
      _read(
        'attendance_records',
        () => _databaseServices.getData(
          path: 'attendance_records',
          column: SupabaseAdminRepository.summaryColumns,
          query: {'employee_id': ?employeeId},
          orderBy: 'work_date',
          greaterThanOrEqual: {'work_date': from},
          lessThan: {'work_date': to},
        ),
      ),
      // A request is made after the day it is about, so every request
      // about this month was created on or after its first day.
      _read(
        'attendance_correction_requests',
        () => _databaseServices.getData(
          path: 'attendance_correction_requests',
          column: _correctionColumns,
          query: {'employee_id': ?employeeId},
          greaterThanOrEqual: {'created_at': '${from}T00:00:00Z'},
        ),
      ),
    ]);

    final sessions = _parse('attendance_records', results[2], (json) {
      final session = AttendanceSessionModel.fromJson(
        json,
        shift: ShiftModel.fromRecord(json),
      );
      return (json['employee_id'] as String, session);
    });
    final days = <String, List<AttendanceSessionEntity>>{};
    for (final (employeeId, session) in sessions) {
      days.putIfAbsent(employeeId, () => []).add(session);
    }
    final dayIds = {for (final (_, session) in sessions) session.id};

    return HrReportInput(
      period: period,
      employees: results[0] as List<EmployeeEntity>,
      schedules: _parse('work_schedules', results[1], _schedule),
      days: days,
      corrections: [
        for (final correction in _parse(
          'attendance_correction_requests',
          results[3],
          CorrectionRequestModel.fromJson,
        ))
          if (dayIds.contains(correction.attendanceId)) correction,
      ].cast<CorrectionRequestEntity>(),
      generatedAt: _now(),
      generatedBy: generatedBy,
      employeeId: employeeId,
    );
  }

  @override
  Future<void> share(Uint8List bytes, String fileName) async {
    try {
      // One report at a time: the previous one (personal data) is removed
      // before the next is written, so files never pile up. It can't be
      // deleted right after sharing: the receiving app may still read it.
      final folder = await _folder();
      if (await folder.exists()) await folder.delete(recursive: true);
      await folder.create(recursive: true);
      final file = File('${folder.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await _share(file, fileName);
    } on FileSystemException catch (e) {
      log('Saving the report failed: ${e.osError?.errorCode}');
      throw AdminFailure.unknown;
    }
  }

  static Future<Directory> _defaultFolder() async =>
      Directory('${(await getTemporaryDirectory()).path}/hr_reports');

  static Future<void> _shareFile(File file, String fileName) =>
      SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          fileNameOverrides: [fileName],
        ),
      );

  static ReportSchedule _schedule(Map<String, dynamic> json) => ReportSchedule(
    id: json['id'] as String,
    name: json['name'] as String,
    timezone: json['timezone'] as String,
    days: [
      for (final day in (json['schedule_days'] as List).cast<Map>())
        ScheduleDay(
          weekday: (day['weekday'] as num).toInt(),
          start: ShiftModel.parseTime(day['starts_at'] as String),
          end: ShiftModel.parseTime(day['ends_at'] as String),
        ),
    ],
  );

  Future<Object?> _read(String name, Future<dynamic> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on PostgrestException catch (e) {
      log('$name failed: code ${e.code}');
      throw SupabaseAdminRepository.failureFor(e.code, e.message);
    } on AdminFailure {
      rethrow;
    } on Exception catch (e) {
      log('$name failed: ${e.runtimeType}');
      throw AdminFailure.network;
    }
  }

  static List<T> _parse<T>(
    String name,
    Object? rows,
    T Function(Map<String, dynamic> json) parse,
  ) {
    try {
      return [
        for (final row in (rows as List).cast<Map>())
          parse(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      log('Unreadable $name: ${e.runtimeType}');
      throw AdminFailure.unknown;
    }
  }

  static String _ymd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
