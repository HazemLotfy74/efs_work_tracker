import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../../core/widgets/custom_container.dart';
import '../../../../home/presentation/widgets/custom_status_container.dart';
import '../../manager/location_cubit/location_cubit.dart';
import 'location_details.dart';
import 'location_failure_text.dart';
import 'location_map.dart';
import 'map_placeholder.dart';

/// The card that shows the map and status for each [LocationState].
class LocationCard extends StatelessWidget {
  const LocationCard({super.key, required this.state});

  final LocationState state;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      horizontalPadding: 20,
      verticalPadding: 20,
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 15,
        children: _content(context),
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final l10n = context.l10n;

    switch (state) {
      case LocationInitial() || LocationLoading():
        return [
          const MapPlaceholder(child: CircularProgressIndicator()),
          CustomStatusContainer(tone: StatusTone.warning, text: l10n.locating),
        ];

      case LocationLoaded(:final location):
        return [
          LocationMap(point: LatLng(location.latitude, location.longitude)),
          LocationDetails(location: location),
        ];

      case LocationError(:final failure):
        return [
          MapPlaceholder(
            child: Icon(
              Icons.location_off_outlined,
              color: context.colors.error,
            ),
          ),
          CustomStatusContainer(
            tone: StatusTone.error,
            text: l10n.locationUnavailable,
          ),
          Text(failure.message(l10n), style: context.textTheme.bodySmall),
        ];
    }
  }
}
