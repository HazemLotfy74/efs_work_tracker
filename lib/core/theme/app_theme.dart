import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_text_styles.dart';
import 'app_theme_colors.dart';

/// Builds the app themes from [AppPalette] and [AppTextStyles].
///
/// This is the only place that maps palette values to semantic roles. Both
/// themes go through [_build], so component themes, text colors and the
/// [AppThemeColors] extension stay in sync between light and dark.
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.green500,
      primary: AppPalette.green500,
      onPrimary: AppPalette.white,
      primaryContainer: AppPalette.green50,
      secondary: AppPalette.green850,
      onSecondary: AppPalette.white,
      surface: AppPalette.white,
      onSurface: AppPalette.green850,
      onSurfaceVariant: AppPalette.neutral600,
      surfaceContainerLow: AppPalette.neutral100,
      outlineVariant: AppPalette.neutral200,
      error: AppPalette.red500,
      errorContainer: AppPalette.red50,
    );

    return _build(
      colorScheme: colorScheme,
      scaffoldBackground: AppPalette.neutral100,
      colors: const AppThemeColors(
        headingText: AppPalette.green900,
        fieldLabelText: AppPalette.neutral700,
        inactiveNavText: AppPalette.neutral500,
        secondaryIcon: AppPalette.neutral500,
        inputBackground: AppPalette.neutral50,
        inputIcon: AppPalette.neutral300,
        brandSurface: AppPalette.green900,
        onBrandSurface: AppPalette.white,
        onBrandSurfaceMuted: AppPalette.neutral400,
        onBrandSurfaceSubtle: AppPalette.neutral300,
        brandSurfaceBadge: AppPalette.neutral600,
        brandGradient: _brandGradient,
        warning: AppPalette.amber600,
        warningContainer: AppPalette.amber50,
      ),
    );
  }

  /// Structural dark theme, not enabled in the app yet.
  ///
  /// Values are derived from the brand seed and the light palette as
  /// placeholders. There is no dark design in Figma: replace them once one is
  /// approved.
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.green500,
      brightness: Brightness.dark,
    );

    return _build(
      colorScheme: colorScheme,
      scaffoldBackground: colorScheme.surfaceContainerLowest,
      colors: AppThemeColors(
        headingText: colorScheme.onSurface,
        fieldLabelText: colorScheme.onSurfaceVariant,
        inactiveNavText: colorScheme.onSurfaceVariant,
        secondaryIcon: colorScheme.onSurfaceVariant,
        inputBackground: colorScheme.surfaceContainerHighest,
        inputIcon: colorScheme.onSurfaceVariant,
        // Brand surfaces are already dark, so they keep their light values.
        brandSurface: AppPalette.green900,
        onBrandSurface: AppPalette.white,
        onBrandSurfaceMuted: AppPalette.neutral400,
        onBrandSurfaceSubtle: AppPalette.neutral300,
        brandSurfaceBadge: AppPalette.neutral600,
        brandGradient: _brandGradient,
        warning: AppPalette.amber50,
        warningContainer: AppPalette.amber800,
      ),
    );
  }

  static const _brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppPalette.green950, AppPalette.green900, AppPalette.green800],
  );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required AppThemeColors colors,
  }) {
    final textTheme = _textTheme(colorScheme);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 70,
        titleTextStyle: textTheme.titleMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputBackground,
        prefixIconColor: colors.inputIcon,
        suffixIconColor: colors.inputIcon,
        border: inputBorder,
        enabledBorder: inputBorder,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colors.fieldLabelText,
        ),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        // The design has no selection pill, only the colored icon and label.
        indicatorColor: Colors.transparent,
        indicatorShape: const OutlineInputBorder(borderSide: BorderSide.none),
        height: 86,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colors.inactiveNavText,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    final textTheme =
        TextTheme(
          displaySmall: AppTextStyles.displaySmall,
          headlineMedium: AppTextStyles.headlineMedium,
          headlineSmall: AppTextStyles.headlineSmall,
          titleLarge: AppTextStyles.titleLarge,
          titleMedium: AppTextStyles.titleMedium,
          titleSmall: AppTextStyles.titleSmall,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.labelLarge,
          labelMedium: AppTextStyles.labelMedium,
          labelSmall: AppTextStyles.labelSmall,
        ).apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    return textTheme.copyWith(
      bodySmall: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
