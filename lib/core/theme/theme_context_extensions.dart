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

  /// [style] without its letter spacing in right-to-left (Arabic) text, where
  /// spacing pulls apart the joined letters. For the tracked custom roles
  /// (`overline`, `micro`) used outside the text theme.
  TextStyle tracked(TextStyle style) =>
      Directionality.of(this) == TextDirection.rtl
      ? style.copyWith(letterSpacing: 0)
      : style;
}
