import 'package:flutter/material.dart';

/// Raw light-theme color palette taken from the WorkTrack Figma design.
///
/// Only [AppTheme] should read these. Widgets get colors from
/// `Theme.of(context).colorScheme` or [AppThemeColors.of], so that a dark
/// theme only needs a second set of values in the theme layer.
abstract final class AppColors {
  static const primary = Color(0xFF008C43);
  static const background = Color(0xFFF3F7F5);
  static const white = Colors.white;

  static const textPrimary = Color(0xFF17352E);
  static const textSecondary = Color(0xFF6B8079);
  static const textHeading = Color(0xFF103B31);
  static const textFieldLabel = Color(0xFF42566A);
  static const textNavInactive = Color(0xFF82909E);

  /// Card and bottom navigation borders.
  static const border = Color(0xFFDFE9E4);

  /// Dark attendance card on the dashboard.
  static const attendanceCard = Color(0xFF103B31);

  static const errorSoft = Color(0xFFFEEBED);

  // Not yet confirmed against Figma: estimated from screenshots.
  static const error = Color(0xFFC9334A);
  static const primarySoft = Color(0xFFE3F3EA);
  static const warningBgColor = Color(0xFFFFF4DC);
  static const warningTxTColor = Color(0xFF8D5A1D);
  static const autoClosedColor = Color(0xFFC33B4A);
  static const localTimeColor = Color(0xFF9FB1C1);
  static const lightGreyColor = Color(0xFFAEBDCA);
}
