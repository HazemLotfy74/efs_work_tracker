import 'attendance_type.dart';
import 'location_entity.dart';

/// Everything captured for one check-in or check-out: time, location and
/// selfie.
///
/// Filled step by step. Each field is `null` until its step is done, and a
/// step only unlocks the next one once its field is set (see [unlockedStep]).
class AttendanceEventEntity {
  const AttendanceEventEntity({
    required this.type,
    this.time,
    this.location,
    this.selfiePath,
    this.selfieCapturedAt,
  });

  final AttendanceType type;

  /// When the user started this event on the Prepare step (UTC).
  final DateTime? time;

  final LocationEntity? location;

  /// Local file path of the selfie taken with the camera.
  final String? selfiePath;

  /// When the selfie was taken (UTC).
  final DateTime? selfieCapturedAt;

  bool get hasTime => time != null;
  bool get hasLocation => location != null;
  bool get hasSelfie => selfiePath != null;
  bool get isComplete => hasTime && hasLocation && hasSelfie;

  /// The furthest step the user may open:
  /// 0 Prepare, 1 Location, 2 Selfie, 3 Review.
  int get unlockedStep {
    if (!hasTime) return 0;
    if (!hasLocation) return 1;
    if (!hasSelfie) return 2;
    return 3;
  }

  AttendanceEventEntity copyWith({
    DateTime? time,
    LocationEntity? Function()? location,
    String? selfiePath,
    DateTime? selfieCapturedAt,
  }) {
    return AttendanceEventEntity(
      type: type,
      time: time ?? this.time,
      // A function, so the location can be cleared with `() => null`.
      location: location != null ? location() : this.location,
      selfiePath: selfiePath ?? this.selfiePath,
      selfieCapturedAt: selfieCapturedAt ?? this.selfieCapturedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AttendanceEventEntity &&
      other.type == type &&
      other.time == time &&
      other.location == location &&
      other.selfiePath == selfiePath &&
      other.selfieCapturedAt == selfieCapturedAt;

  @override
  int get hashCode =>
      Object.hash(type, time, location, selfiePath, selfieCapturedAt);
}
