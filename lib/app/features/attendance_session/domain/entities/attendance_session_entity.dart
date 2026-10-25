import 'attendance_event_entity.dart';
import 'shift_entity.dart';

/// One working day: a check-in and, once the user leaves, a check-out.
class AttendanceSessionEntity {
  const AttendanceSessionEntity({
    required this.id,
    required this.checkIn,
    required this.shift,
    this.checkOut,
  });

  /// Backend id (Supabase row id later).
  final String id;
  final AttendanceEventEntity checkIn;

  /// `null` while the user is still working.
  final AttendanceEventEntity? checkOut;

  /// The shift for this day, saved with the session.
  final ShiftEntity shift;

  /// `true` from check-in until check-out.
  bool get isActive => checkOut == null;

  DateTime get checkInTime => checkIn.time!;
  DateTime? get checkOutTime => checkOut?.time;

  /// Worked time: until [now] while active, until check-out once finished.
  Duration workedDuration([DateTime? now]) =>
      (checkOutTime ?? now ?? DateTime.now()).difference(checkInTime);

  /// How early the user checked out; zero while active or when on time.
  Duration get earlyLeave {
    final out = checkOutTime;
    return out == null ? Duration.zero : shift.earlyLeaveFor(out);
  }

  AttendanceSessionEntity copyWith({AttendanceEventEntity? checkOut}) {
    return AttendanceSessionEntity(
      id: id,
      checkIn: checkIn,
      shift: shift,
      checkOut: checkOut ?? this.checkOut,
    );
  }
}
