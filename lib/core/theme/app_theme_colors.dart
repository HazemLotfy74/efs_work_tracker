import 'package:flutter/material.dart';

/// Semantic colors that have no slot in Material's [ColorScheme].
///
/// Standard roles (primary, surface, onSurface, error, outlineVariant, ...)
/// stay in the [ColorScheme]; only app-specific roles live here. Registered on
/// both [AppTheme.light] and [AppTheme.dark]. Read them with
/// `context.appColors`.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.headingText,
    required this.fieldLabelText,
    required this.inactiveNavText,
    required this.secondaryIcon,
    required this.inputBackground,
    required this.inputIcon,
    required this.brandSurface,
    required this.onBrandSurface,
    required this.onBrandSurfaceMuted,
    required this.onBrandSurfaceSubtle,
    required this.brandSurfaceBadge,
    required this.brandGradient,
    required this.warning,
    required this.warningContainer,
  });

  /// Emphasised headings and names, darker than `onSurface`.
  final Color headingText;

  /// Form field labels.
  final Color fieldLabelText;

  /// Unselected bottom navigation labels.
  final Color inactiveNavText;

  /// Supporting icons next to secondary text (location, metadata).
  final Color secondaryIcon;

  /// Fill of text fields.
  final Color inputBackground;

  /// Prefix and suffix icons inside text fields.
  final Color inputIcon;

  /// Dark brand surface of hero cards (dashboard attendance card, attendance
  /// details header).
  final Color brandSurface;

  /// Main text and icons on [brandSurface], and its button background.
  final Color onBrandSurface;

  /// Secondary text on [brandSurface] ("Current local time", dates).
  final Color onBrandSurfaceMuted;

  /// Tertiary text and icons on [brandSurface] (shift note, captions).
  final Color onBrandSurfaceSubtle;

  /// Status badge background on [brandSurface].
  final Color brandSurfaceBadge;

  /// Full-screen background of the auth screens.
  final LinearGradient brandGradient;

  /// Pending / needs-review status: badge dot, banner text and icons.
  final Color warning;

  /// Background of warning banners and pending badges.
  final Color warningContainer;

  @override
  AppThemeColors copyWith({
    Color? headingText,
    Color? fieldLabelText,
    Color? inactiveNavText,
    Color? secondaryIcon,
    Color? inputBackground,
    Color? inputIcon,
    Color? brandSurface,
    Color? onBrandSurface,
    Color? onBrandSurfaceMuted,
    Color? onBrandSurfaceSubtle,
    Color? brandSurfaceBadge,
    LinearGradient? brandGradient,
    Color? warning,
    Color? warningContainer,
  }) {
    return AppThemeColors(
      headingText: headingText ?? this.headingText,
      fieldLabelText: fieldLabelText ?? this.fieldLabelText,
      inactiveNavText: inactiveNavText ?? this.inactiveNavText,
      secondaryIcon: secondaryIcon ?? this.secondaryIcon,
      inputBackground: inputBackground ?? this.inputBackground,
      inputIcon: inputIcon ?? this.inputIcon,
      brandSurface: brandSurface ?? this.brandSurface,
      onBrandSurface: onBrandSurface ?? this.onBrandSurface,
      onBrandSurfaceMuted: onBrandSurfaceMuted ?? this.onBrandSurfaceMuted,
      onBrandSurfaceSubtle: onBrandSurfaceSubtle ?? this.onBrandSurfaceSubtle,
      brandSurfaceBadge: brandSurfaceBadge ?? this.brandSurfaceBadge,
      brandGradient: brandGradient ?? this.brandGradient,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppThemeColors(
      headingText: mix(headingText, other.headingText),
      fieldLabelText: mix(fieldLabelText, other.fieldLabelText),
      inactiveNavText: mix(inactiveNavText, other.inactiveNavText),
      secondaryIcon: mix(secondaryIcon, other.secondaryIcon),
      inputBackground: mix(inputBackground, other.inputBackground),
      inputIcon: mix(inputIcon, other.inputIcon),
      brandSurface: mix(brandSurface, other.brandSurface),
      onBrandSurface: mix(onBrandSurface, other.onBrandSurface),
      onBrandSurfaceMuted: mix(onBrandSurfaceMuted, other.onBrandSurfaceMuted),
      onBrandSurfaceSubtle: mix(
        onBrandSurfaceSubtle,
        other.onBrandSurfaceSubtle,
      ),
      brandSurfaceBadge: mix(brandSurfaceBadge, other.brandSurfaceBadge),
      brandGradient: LinearGradient.lerp(
        brandGradient,
        other.brandGradient,
        t,
      )!,
      warning: mix(warning, other.warning),
      warningContainer: mix(warningContainer, other.warningContainer),
    );
  }
}
