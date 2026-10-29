import '../../domain/entities/correction_request_entity.dart';

/// [CorrectionRequestEntity] from an `attendance_correction_requests` row,
/// optionally with its employee (`employee`) and attendance day
/// (`attendance`) embedded.
class CorrectionRequestModel extends CorrectionRequestEntity {
  const CorrectionRequestModel({
    required super.id,
    required super.employeeId,
    required super.attendanceId,
    required super.proposedCheckIn,
    required super.proposedCheckOut,
    required super.reason,
    required super.status,
    required super.createdAt,
    super.reviewedAt,
    super.reviewNote,
    super.employeeName,
    super.employeeCode,
    super.workDate,
    super.timezone,
    super.actualCheckIn,
  });

  /// Throws when a required column is missing or malformed.
  factory CorrectionRequestModel.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] as Map?;
    final attendance = json['attendance'] as Map?;
    final workDate = attendance?['work_date'] as String?;
    return CorrectionRequestModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      attendanceId: json['attendance_id'] as String,
      proposedCheckIn: DateTime.parse(json['proposed_checkin'] as String),
      proposedCheckOut: _time(json['proposed_checkout']),
      reason: json['reason'] as String,
      status: CorrectionStatus.fromName(json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: _time(json['reviewed_at']),
      reviewNote: json['review_note'] as String?,
      employeeName: employee?['full_name'] as String?,
      employeeCode: employee?['employee_code'] as String?,
      workDate: workDate == null ? null : _date(workDate),
      timezone: attendance?['timezone'] as String?,
      actualCheckIn: _time(attendance?['actual_checkin']),
    );
  }

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.parse(value) : null;

  static DateTime _date(String value) {
    final date = DateTime.parse(value);
    return DateTime(date.year, date.month, date.day);
  }
}
