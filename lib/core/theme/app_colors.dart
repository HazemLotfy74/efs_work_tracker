import 'package:flutter/material.dart';

/// Color tokens taken from the WorkTrack Figma design.
abstract final class AppColors {
  static const primary = Color(0xFF008C43);
  static const background = Color(0xFFF3F7F5);
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF17352E);
  static const textSecondary = Color(0xFF6B8079);

  static const errorSoft = Color(0xFFFEEBED);

  // Not yet confirmed against Figma: estimated from screenshots.
  static const error = Color(0xFFC9334A);
  static const primarySoft = Color(0xFFE3F3EA);
}
