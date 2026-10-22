import 'package:flutter/material.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../../../../../core/theme/theme_context_extensions.dart';
import '../../../../home/presentation/widgets/custom_status_container.dart';
import '../../../domain/entities/location_entity.dart';

/// Badge, address, accuracy and privacy note under the map.
class LocationDetails extends StatelessWidget {
  const LocationDetails({super.key, required this.location});

  final LocationEntity location;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = context.textTheme;
    final time = TimeOfDay.fromDateTime(location.capturedAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 15,
      children: [
        CustomStatusContainer(
          tone: StatusTone.success,
          text: l10n.locationVerified,
        ),
        Text(
          location.address ?? l10n.currentLocation,
          style: textTheme.titleSmall,
        ),
        Text(
          l10n.locationAccuracy(
            location.accuracyMeters.round(),
            time.format(context),
          ),
          style: textTheme.bodySmall,
        ),
        Text(l10n.coordinatesPrivate, style: textTheme.bodySmall),
      ],
    );
  }
}
