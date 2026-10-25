import '../../domain/entities/attendance_event_entity.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/repositories/attendance_repository.dart';

/// Keeps today's session in memory until Supabase is added.
///
/// Follows the same rules the backend will: one session per day, and you
/// can only check out of the active session.
class InMemoryAttendanceRepository implements AttendanceRepository {
  InMemoryAttendanceRepository({this.shift = ShiftEntity.standard});

  final ShiftEntity shift;
  AttendanceSessionEntity? _session;

  @override
  Future<ShiftEntity> getShift() async => shift;

  @override
  Future<AttendanceSessionEntity?> getTodaySession() async {
    final session = _session;
    if (session == null || !_isToday(session.checkInTime)) return null;
    return session;
  }

  @override
  Future<AttendanceSessionEntity> checkIn(AttendanceEventEntity event) async {
    if (await getTodaySession() != null) {
      throw StateError('Already checked in today.');
    }
    final session = AttendanceSessionEntity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      checkIn: event,
      shift: shift,
    );
    _session = session;
    return session;
  }

  @override
  Future<AttendanceSessionEntity> checkOut(
    AttendanceSessionEntity session,
    AttendanceEventEntity event,
  ) async {
    final current = _session;
    if (current == null || current.id != session.id || !current.isActive) {
      throw StateError('No active session to check out of.');
    }
    final finished = current.copyWith(checkOut: event);
    _session = finished;
    return finished;
  }

  static bool _isToday(DateTime time) {
    final now = DateTime.now();
    final local = time.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }
}
