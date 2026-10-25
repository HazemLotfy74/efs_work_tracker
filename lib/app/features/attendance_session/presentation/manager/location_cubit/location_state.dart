part of 'location_cubit.dart';

sealed class LocationState {
  const LocationState();
}

/// The Location step has not been opened yet.
final class LocationInitial extends LocationState {
  const LocationInitial();
}

final class LocationLoading extends LocationState {
  const LocationLoading();
}

final class LocationLoaded extends LocationState {
  const LocationLoaded(this.location);
  final LocationEntity location;
}

final class LocationError extends LocationState {
  const LocationError(this.failure);

  final LocationFailure failure;
}
