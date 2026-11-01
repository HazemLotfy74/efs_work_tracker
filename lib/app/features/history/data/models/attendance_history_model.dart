import '../../../attendance_session/data/models/attendance_session_model.dart';
import '../../../attendance_session/data/models/shift_model.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';

/// Maps a Supabase history row to the shared attendance domain entity.
/// Reuses the established event, timezone and corrected-duration mapping.
class AttendanceHistoryModel {
  const AttendanceHistoryModel._(this._session);

  factory AttendanceHistoryModel.fromJson(Map<String, dynamic> json) =>
      AttendanceHistoryModel._(
        AttendanceSessionModel.fromJson(
          json,
          shift: ShiftModel.fromRecord(json),
        ),
      );

  static const columns =
      'id, work_date, timezone, scheduled_start, scheduled_end, '
      'grace_minutes, actual_checkin, actual_checkout, auto_closed, '
      'auto_closed_at, auto_close_policy, auto_close_deadline, '
      'effective_checkin, effective_checkout, has_correction, '
      'late_minutes, attendance_events(event_type, occurred_at, latitude, '
      'longitude, accuracy_m, selfie_path)';

  final AttendanceSessionEntity _session;
  AttendanceSessionEntity toEntity() => _session;
}
