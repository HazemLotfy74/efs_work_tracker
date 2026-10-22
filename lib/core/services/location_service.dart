import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../errors/location_errors.dart';

/// Reads the device GPS position.
class LocationService {
  const LocationService();

  /// Returns the current position, or throws a [LocationFailure].
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationFailure.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationFailure.permissionDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure.permissionDeniedForever;
    }

    try {
      // `high` asks for GPS accuracy but does not guarantee it; check
      // `position.accuracy` (meters) for the real value.
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw LocationFailure.timeout;
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
