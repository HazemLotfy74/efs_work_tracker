import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../core/theme/theme_context_extensions.dart';

/// Map with a fixed pin on [point]. The user cannot move or zoom it.
class LocationMap extends StatelessWidget {
  const LocationMap({super.key, required this.point});

  final LatLng point;

  /// Public OpenStreetMap tiles: free for development, not for heavy
  /// production traffic. Change this URL to switch provider.
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 150,
        // IgnorePointer blocks every touch, so the map is read-only.
        child: IgnorePointer(
          child: FlutterMap(
            // New point -> new map, so the camera moves to it.
            key: ValueKey(point),
            options: MapOptions(
              initialCenter: point,
              initialZoom: 17,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
                keyboardOptions: KeyboardOptions.disabled(),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.efs.efs_work_tracker',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter, // pin tip on the point
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
              const _Attribution(),
            ],
          ),
        ),
      ),
    );
  }
}

/// "© OpenStreetMap contributors" label required by the OSM licence.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: ColoredBox(
        color: context.colors.surface.withValues(alpha: 0.8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Text(
            '© OpenStreetMap contributors',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
