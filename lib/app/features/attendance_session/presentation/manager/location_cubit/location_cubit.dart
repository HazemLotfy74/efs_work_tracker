import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../../core/errors/location_errors.dart';
import '../../../../../../core/services/address_service.dart';
import '../../../../../../core/services/location_service.dart';
import '../../../domain/entities/location_entity.dart';

part 'location_state.dart';

/// Holds the device location for one check-in.
///
/// Created in `CheckInView` (above the pages), so the location is kept when
/// the user moves between steps.
class LocationCubit extends Cubit<LocationState> {
  LocationCubit({
    this._locationService = const LocationService(),
    this._addressService = const AddressService(),
    this.languageCode = 'en',
  }) : super(const LocationInitial());

  final LocationService _locationService;
  final AddressService _addressService;

  /// Language of the address text.
  final String languageCode;

  /// Loads the location the first time only (safe to call many times).
  void ensureLocation() {
    if (state is LocationInitial) fetchLocation();
  }

  Future<void> fetchLocation() async {
    if (state is LocationLoading) return;
    emit(const LocationLoading());

    final Position position;
    try {
      position = await _locationService.getCurrentPosition();
    } catch (error) {
      if (isClosed) return;
      emit(
        LocationError(
          error is LocationFailure ? error : LocationFailure.unknown,
        ),
      );
      return;
    }
    if (isClosed) return;

    final location = LocationEntity(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      capturedAt: position.timestamp.toUtc(),
      isMocked: position.isMocked,
    );

    // 1. Show the map now.
    emit(LocationLoaded(location));

    // 2. Add the address when it arrives.
    final address = await _addressService.getAddress(
      location.latitude,
      location.longitude,
      languageCode: languageCode,
    );
    final current = state;
    final stillShowing =
        current is LocationLoaded && current.location == location;
    // Skip it if the user retried in the meantime (a newer location).
    if (isClosed || address == null || !stillShowing) return;
    emit(LocationLoaded(location.copyWith(address: address)));
  }

  /// The captured location, or `null` if there is none yet. Use this when
  /// saving the check-in (convert with `LocationModel.fromEntity`).
  LocationEntity? get location {
    final current = state;
    return current is LocationLoaded ? current.location : null;
  }

  Future<void> openSettings() async {
    final current = state;
    if (current is! LocationError) return;
    if (current.failure == LocationFailure.serviceDisabled) {
      await _locationService.openLocationSettings();
    } else {
      await _locationService.openAppSettings();
    }
  }

  /// When the user comes back from the settings, try again.
  void retryAfterSettings() {
    final current = state;
    if (current is LocationError && current.failure.needsSettings) {
      fetchLocation();
    }
  }
}
