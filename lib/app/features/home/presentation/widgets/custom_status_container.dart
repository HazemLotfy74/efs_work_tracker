import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';

/// Meaning of a status badge; each tone maps to theme colors.
enum StatusTone { success, warning, error }

/// Pill badge with a colored dot, e.g. "Within grace period", "Needs review".
class CustomStatusContainer extends StatelessWidget {
  const CustomStatusContainer({
    super.key,
    required this.tone,
    required this.text,
    this.dense = false,
  });

  final StatusTone tone;
  final String text;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final appColors = context.appColors;
    final (background, foreground) = switch (tone) {
      StatusTone.success => (colors.primaryContainer, colors.primary),
      StatusTone.warning => (appColors.warningContainer, appColors.warning),
      StatusTone.error => (colors.errorContainer, colors.error),
    };

    return CustomContainer(
      borderWidth: dense ? 0 : 1,
      borderRadius: 12.5,
      horizontalPadding: dense ? 6 : null,
      verticalPadding: dense ? 4 : null,
      containerColor: background,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Container(
            width: dense ? 5 : 8,
            height: dense ? 5 : 8,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          // Long or translated text wraps instead of overflowing.
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
