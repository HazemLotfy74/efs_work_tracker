import '../../../../../core/errors/attendance_errors.dart';
import '../../domain/entities/attendance_event_entity.dart';
import '../../domain/entities/attendance_session_entity.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/repositories/attendance_repository.dart';

/// Keeps today's session in memory, for tests and offline UI work.
///
/// Follows the same rules as the backend: one session per day, and you
/// can only check out of a session once.
class InMemoryAttendanceRepository implements AttendanceRepository {
  InMemoryAttendanceRepository({this.shift = ShiftEntity.standard});

  final ShiftEntity shift;
  AttendanceSessionEntity? _session;

  @override
  Future<AttendanceToday> getToday() async {
    final session = _session;
    if (session == null || !_isToday(session.checkInTime)) {
      return (shift: shift, session: null);
    }
    return (shift: shift, session: session);
  }

  @override
  Future<List<AttendanceSessionEntity>> getHistory({int limit = 60}) async {
    final session = _session;
    return session == null ? const [] : [session];
  }

  @override
  Future<AttendanceSessionEntity?> getSession(String id) async {
    final session = _session;
    return session?.id == id ? session : null;
  }

  @override
  Future<AttendanceSessionEntity> checkIn(AttendanceEventEntity event) async {
    if ((await getToday()).session != null) {
      throw AttendanceFailure.alreadyCheckedIn;
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
    if (current == null || current.id != session.id) {
      throw AttendanceFailure.notCheckedIn;
    }
    if (!current.canCheckOut) throw AttendanceFailure.alreadyCheckedOut;
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
