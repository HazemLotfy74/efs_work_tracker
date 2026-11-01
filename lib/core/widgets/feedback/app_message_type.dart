import 'package:flutter/material.dart';

import '../../theme/theme_context_extensions.dart';

/// What a message tells the user; each type has its own icon and colors.
enum AppMessageType {
  success,
  error,
  warning,
  info;

  IconData get icon => switch (this) {
    success => Icons.check_circle_outline,
    error => Icons.error_outline,
    warning => Icons.warning_amber_rounded,
    info => Icons.info_outline,
  };

  /// (background, foreground) from the theme, for both light and dark.
  (Color, Color) colorsOf(BuildContext context) {
    final colors = context.colors;
    final appColors = context.appColors;
    return switch (this) {
      success => (colors.primaryContainer, colors.primary),
      error => (colors.errorContainer, colors.error),
      warning => (appColors.warningContainer, appColors.warning),
      info => (colors.surfaceContainerHighest, colors.onSurface),
    };
  }
}
