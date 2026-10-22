import 'package:flutter/material.dart';

import '../../../../../../core/theme/theme_context_extensions.dart';

/// Same size as the map; shown while loading or on error.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
