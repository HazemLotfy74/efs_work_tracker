import 'package:flutter/material.dart';

/// Primitive color values of the WorkTrack light design (Figma).
///
/// Names describe the hue and shade, not where a color is used. Only the theme
/// layer ([AppTheme]) reads this class: widgets get colors through their
/// semantic role, `context.colors` ([ColorScheme]) or `context.appColors`
/// ([AppThemeColors]), so a dark theme only needs new role values.
///
/// The app's neutrals are slightly green-tinted, which is why they live in one
/// `neutral` ramp instead of a pure grey one.
abstract final class AppPalette {
  static const white = Color(0xFFFFFFFF);

  static const neutral50 = Color(0xFFF8FAFB);
  static const neutral100 = Color(0xFFF3F7F5);
  static const neutral200 = Color(0xFFDFE9E4);
  static const neutral300 = Color(0xFFAEBDCA);
  static const neutral400 = Color(0xFF9FB1C1);
  static const neutral500 = Color(0xFF82909E);
  static const neutral600 = Color(0xFF6B8079);
  static const neutral700 = Color(0xFF42566A);

  static const green50 = Color(0xFFE8F5EE);
  static const green500 = Color(0xFF008C43);
  static const green800 = Color(0xFF155843);
  static const green850 = Color(0xFF17352E);
  static const green900 = Color(0xFF103B31);
  static const green950 = Color(0xFF06251E);

  // Not yet confirmed against Figma: estimated from screenshots.
  static const red50 = Color(0xFFFEEBED);
  static const red500 = Color(0xFFC9334A);
  static const amber50 = Color(0xFFFFF4DC);
  static const amber600 = Color(0xFFB56608);
  static const amber800 = Color(0xFF8D5A1D);
}
