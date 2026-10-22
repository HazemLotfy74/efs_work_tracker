import '../../domain/entities/location_entity.dart';

/// [LocationEntity] plus conversion to and from a Supabase row.
///
/// The JSON keys are the table's column names. Change them here if your
/// table uses different names.
class LocationModel extends LocationEntity {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    required super.accuracyMeters,
    required super.capturedAt,
    super.address,
    super.isMocked,
  });

  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracyMeters: entity.accuracyMeters,
      capturedAt: entity.capturedAt,
      address: entity.address,
      isMocked: entity.isMocked,
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      // Postgres numbers can arrive as int or double.
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracy_meters'] as num).toDouble(),
      capturedAt: DateTime.parse(json['captured_at'] as String),
      address: json['address'] as String?,
      isMocked: json['is_mocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'address': address,
      'is_mocked': isMocked,
    };
  }
}
