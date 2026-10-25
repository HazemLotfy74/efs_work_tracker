import '../entities/attendance_event_entity.dart';
import '../entities/attendance_session_entity.dart';
import '../entities/shift_entity.dart';

/// Where attendance is loaded from and saved to.
///
/// The app only talks to this interface, never to a database directly.
/// Today `InMemoryAttendanceRepository` implements it (data is lost when the
/// app restarts). To move to Supabase:
/// 1. Add `SupabaseAttendanceRepository implements AttendanceRepository` in
///    `data/repositories/`, with models in `data/models/` (like
///    `LocationModel`) to turn rows into entities.
/// 2. Change the one line in `main.dart` that creates the repository.
/// Nothing in the UI or cubits has to change.
abstract interface class AttendanceRepository {
  /// The signed-in employee's shift.
  Future<ShiftEntity> getShift();

  /// Today's session, or `null` when the user has not checked in today.
  Future<AttendanceSessionEntity?> getTodaySession();

  /// Saves a finished check-in flow and returns the new, active session.
  Future<AttendanceSessionEntity> checkIn(AttendanceEventEntity event);

  /// Saves a finished check-out flow on [session] and returns it finished.
  Future<AttendanceSessionEntity> checkOut(
    AttendanceSessionEntity session,
    AttendanceEventEntity event,
  );
}
