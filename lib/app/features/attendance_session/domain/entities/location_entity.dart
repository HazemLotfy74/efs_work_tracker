/// The location captured as check-in evidence.
///
/// Plain Dart, no packages: the UI, the cubit and (later) the repository all
/// use this type, so none of them depend on geolocator.
class LocationEntity {
  const LocationEntity({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
    this.address,
    this.isMocked = false,
  });

  final double latitude;
  final double longitude;

  /// How far off the reading may be, in meters (reported by the phone).
  final double accuracyMeters;

  /// When the phone took the reading (UTC).
  final DateTime capturedAt;

  /// "Street, district, city" for display; `null` when not found.
  final String? address;

  /// `true` when Android reports the position comes from a fake-GPS app.
  final bool isMocked;

  LocationEntity copyWith({String? address}) {
    return LocationEntity(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      capturedAt: capturedAt,
      address: address ?? this.address,
      isMocked: isMocked,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LocationEntity &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.accuracyMeters == accuracyMeters &&
      other.capturedAt == capturedAt &&
      other.address == address &&
      other.isMocked == isMocked;

  @override
  int get hashCode => Object.hash(
    latitude,
    longitude,
    accuracyMeters,
    capturedAt,
    address,
    isMocked,
  );
}
