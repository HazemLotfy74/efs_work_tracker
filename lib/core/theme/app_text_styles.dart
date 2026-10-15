import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Manrope text styles used across the app.
abstract final class AppTextStyles {
  static TextStyle get headline => GoogleFonts.manrope(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.7,
    color: AppColors.textPrimary,
  );

  static TextStyle get appBarTitle => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get button => GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: Colors.white,
  );

  static TextStyle get bodySmall => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textSecondary,
  );
}
