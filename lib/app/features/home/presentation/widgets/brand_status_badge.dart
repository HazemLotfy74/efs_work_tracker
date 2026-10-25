import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';

/// Pill badge with a dot for the dark green attendance card, e.g.
/// "Not Checked In", "Checked In".
class BrandStatusBadge extends StatelessWidget {
  const BrandStatusBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: appColors.brandSurfaceBadge,
        borderRadius: BorderRadius.circular(12.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: appColors.onBrandSurface,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            text,
            style: AppTextStyles.badge.copyWith(
              color: appColors.onBrandSurface,
            ),
          ),
        ],
      ),
    );
  }
}
