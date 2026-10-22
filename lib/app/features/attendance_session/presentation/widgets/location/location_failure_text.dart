import '../../../../../../core/errors/location_errors.dart';
import '../../../../../../l10n/app_localizations.dart';

/// Message shown to the user for each [LocationFailure].
extension LocationFailureText on LocationFailure {
  String message(AppLocalizations l10n) {
    return switch (this) {
      LocationFailure.serviceDisabled => l10n.locationServiceDisabled,
      LocationFailure.permissionDenied => l10n.locationPermissionDenied,
      LocationFailure.permissionDeniedForever =>
        l10n.locationPermissionDeniedForever,
      LocationFailure.timeout => l10n.locationTimeout,
      LocationFailure.unknown => l10n.locationUnknownError,
    };
  }
}
