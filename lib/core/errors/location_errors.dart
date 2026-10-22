/// Why the device location could not be read.
///
/// It is an [Exception] itself, so the service can simply
/// `throw LocationFailure.timeout;`.
enum LocationFailure implements Exception {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown;

  /// These can only be fixed in the phone settings, not by retrying.
  bool get needsSettings =>
      this == serviceDisabled || this == permissionDeniedForever;
}
