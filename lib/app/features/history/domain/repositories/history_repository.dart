import '../../../attendance_session/domain/entities/attendance_session_entity.dart';

/// History reads are independent of today's check-in/check-out operations.
abstract interface class HistoryRepository {
  Future<List<AttendanceSessionEntity>> getMonth(DateTime month);
}
