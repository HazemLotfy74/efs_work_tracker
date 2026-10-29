import '../entities/attendance_event_entity.dart';
import '../entities/attendance_session_entity.dart';
import '../entities/shift_entity.dart';

/// Today's shift and session, read together so they always match.
///
/// [shift] is `null` on a day off; [session] is `null` before check-in.
typedef AttendanceToday = ({
  ShiftEntity? shift,
  AttendanceSessionEntity? session,
});

/// Where attendance is loaded from and saved to.
///
/// The app only talks to this interface, never to a database directly.
/// `SupabaseAttendanceRepository` is the real one; the in-memory one is for
/// tests. Every method throws an `AttendanceFailure`
/// (core/errors/attendance_errors.dart) on error.
abstract interface class AttendanceRepository {
  /// The signed-in employee's attendance for today's work date, in the
  /// company's timezone.
  Future<AttendanceToday> getToday();

  /// The signed-in employee's own attendance days, newest first.
  Future<List<AttendanceSessionEntity>> getHistory({int limit = 60});

  /// One of the signed-in employee's own days, with the overtime approved
  /// for its date; `null` when there is no such record.
  Future<AttendanceSessionEntity?> getSession(String id);

  /// Saves a finished check-in flow and returns the new, active session.
  Future<AttendanceSessionEntity> checkIn(AttendanceEventEntity event);

  /// Saves a finished check-out flow on [session] and returns it finished.
  Future<AttendanceSessionEntity> checkOut(
    AttendanceSessionEntity session,
    AttendanceEventEntity event,
  );
}
