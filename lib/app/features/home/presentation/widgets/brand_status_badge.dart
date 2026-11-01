import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';

/// What a [BrandStatusBadge] says about the day.
enum BrandBadgeTone {
  /// Not checked in yet, or checked out.
  neutral,

  /// Checked in, the session is running.
  active,

  /// Closed automatically; the hours need review.
  warning,
}

/// Pill badge with a dot for the dark green attendance card, e.g.
/// "Not Checked In", "Checked In".
class BrandStatusBadge extends StatelessWidget {
  const BrandStatusBadge({
    super.key,
    required this.text,
    this.tone = BrandBadgeTone.neutral,
  });

  final String text;
  final BrandBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      BrandBadgeTone.neutral => (
        appColors.brandSurfaceBadge,
        appColors.onBrandSurface,
      ),
      BrandBadgeTone.active => (colors.primary, colors.onPrimary),
      BrandBadgeTone.warning => (appColors.warningContainer, appColors.warning),
    };
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.badge.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
