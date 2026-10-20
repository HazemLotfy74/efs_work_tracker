import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_theme_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      primaryContainer: AppColors.primarySoft,
      onPrimary: AppColors.lightPrimary,
      secondary: AppColors.textPrimary,
      surface: AppColors.white,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outlineVariant: AppColors.border,
      error: AppColors.error,
      errorContainer: AppColors.errorSoft,
    );

    return _build(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.background,
      colors: const AppThemeColors(
        textHeading: AppColors.textHeading,
        fieldLabel: AppColors.textFieldLabel,
        navInactive: AppColors.textNavInactive,
        attendanceCard: AppColors.attendanceCard,
        onAttendanceCard: AppColors.white,
        onAttendanceCardMuted: AppColors.localTimeColor,
        onAttendanceCardSubtle: AppColors.lightGreyColor,
        attendanceCardBadge: AppColors.textSecondary,
        warningContainer: AppColors.warningBgColor,
        onWarningContainer: AppColors.warningTxTColor,
        autoClosed: AppColors.autoClosedColor,
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
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return _build(
      colorScheme: colorScheme,
      scaffoldBackground: colorScheme.surfaceContainerLowest,
      colors: AppThemeColors(
        textHeading: colorScheme.onSurface,
        fieldLabel: colorScheme.onSurfaceVariant,
        navInactive: colorScheme.onSurfaceVariant,
        // The attendance card is already a dark surface, so it keeps its
        // light-theme colors.
        attendanceCard: AppColors.attendanceCard,
        onAttendanceCard: AppColors.white,
        onAttendanceCardMuted: AppColors.localTimeColor,
        onAttendanceCardSubtle: AppColors.lightGreyColor,
        attendanceCardBadge: AppColors.textSecondary,
        warningContainer: AppColors.warningTxTColor,
        onWarningContainer: AppColors.warningBgColor,
        autoClosed: colorScheme.error,
      ),
    );
  }

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required AppThemeColors colors,
  }) {
    final textTheme = _textTheme(colorScheme);

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
        labelStyle: textTheme.labelMedium?.copyWith(color: colors.fieldLabel),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
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
                : colors.navInactive,
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
