import 'package:efs_work_tracker/core/services/address_service.dart';
import 'package:efs_work_tracker/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

/// Fake GPS: each test decides what the next request returns.
class FakeLocationService implements LocationService {
  FakeLocationService(this.result);

  Future<Position> Function() result;
  int requests = 0;
  int locationSettingsOpened = 0;
  int appSettingsOpened = 0;

  @override
  Future<Position> getCurrentPosition() {
    requests++;
    return result();
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened++;
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return true;
  }
}

/// Fake address lookup; returns no address unless a test sets one.
class FakeAddressService implements AddressService {
  Future<String?> Function() result = () async => null;
  String? lastLanguage;

  @override
  Future<String?> getAddress(
    double latitude,
    double longitude, {
    String languageCode = 'en',
  }) {
    lastLanguage = languageCode;
    return result();
  }
}

Position testPosition() => Position(
  latitude: 30.0275,
  longitude: 31.4913,
  timestamp: DateTime.utc(2026, 10, 22, 8, 7),
  accuracy: 8,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);
