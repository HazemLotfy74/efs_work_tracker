import 'package:flutter/material.dart';

import 'app_theme_colors.dart';

/// Short access to the active theme from widgets.
///
/// ```dart
/// Text('Today', style: context.textTheme.titleSmall)
/// Icon(Icons.place, color: context.appColors.secondaryIcon)
/// ```
extension ThemeContextX on BuildContext {
  ColorScheme get colors => ColorScheme.of(this);

  TextTheme get textTheme => TextTheme.of(this);

  /// App-specific semantic colors. Registered by both [AppTheme] themes.
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>()!;
}
