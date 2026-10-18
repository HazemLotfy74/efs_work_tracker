import 'package:flutter/material.dart';

/// Typography tokens taken from the WorkTrack Figma design (Manrope).
///
/// These are the single source of truth for font sizes, weights, line heights
/// and letter spacing. [AppTheme] maps the Material roles of
/// `ThemeData.textTheme` onto them, so widgets should prefer
/// `TextTheme.of(context)` and only reach for the extra roles below
/// (marked "custom") when no Material role fits.
///
/// Colors are not part of the tokens: the theme applies the default text
/// colors and widgets add a color with `copyWith` where Figma differs.
abstract final class AppTextStyles {
  static const fontFamily = 'Manrope';

  static TextStyle _style(
    double fontSize,
    FontWeight fontWeight, {
    double height = 1.5,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static final displaySmall = _style(
    37,
    FontWeight.w700,
    height: 1,
    letterSpacing: -1.2,
  );

  /// Page, auth and full-screen state titles. 26 / 31.2, ExtraBold, -0.7.
  static final headlineMedium = _style(
    26,
    FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.7,
  );

  /// Home greeting. 22 / 28.6, ExtraBold, -0.4.
  static final headlineSmall = _style(
    22,
    FontWeight.w800,
    height: 1.3,
    letterSpacing: -0.4,
  );

  /// Metric and statistic values. 18 / 27, Bold.
  static final titleLarge = _style(18, FontWeight.w700);

  /// App bar titles and avatar initials. 16 / 24, ExtraBold.
  static final titleMedium = _style(16, FontWeight.w800);

  /// Section and card titles. 14 / 21, ExtraBold.
  static final titleSmall = _style(14, FontWeight.w800);

  /// Input text and primary body copy. 13 / 19.5, Regular.
  static final bodyLarge = _style(13, FontWeight.w400);

  /// Descriptions and state messages. 12 / 19.2, Regular.
  static final bodyMedium = _style(12, FontWeight.w400, height: 1.6);

  /// Captions, helper text and metadata. 10 / 15, Regular.
  static final bodySmall = _style(10, FontWeight.w400);

  /// Button labels. 15 / 22.5, Bold.
  static final labelLarge = _style(15, FontWeight.w700);

  /// Form field labels and text links. 12 / 18, Bold.
  static final labelMedium = _style(12, FontWeight.w700);

  /// Bottom navigation labels and small bold values. 9 / 13.5, Bold.
  static final labelSmall = _style(9, FontWeight.w700);

  // Custom roles with no Material equivalent.

  /// Intro paragraph under auth titles. 14 / 22.4, Regular.
  static final lead = _style(14, FontWeight.w400, height: 1.6);

  /// Title of a list row, notice or summary value. 11 / 16.5, Bold.
  static final itemTitle = _style(11, FontWeight.w700);

  /// Label of a summary row. 11 / 16.5, Regular.
  static final itemBody = _style(11, FontWeight.w400);

  /// Timeline titles, segmented control and inline links. 10 / 15, Bold.
  static final captionStrong = _style(10, FontWeight.w700);

  /// Metric labels and secondary lines in rows. 9 / 13.5, Regular.
  static final meta = _style(9, FontWeight.w400);

  /// Uppercase date eyebrow. 9 / 13.5, ExtraBold, +1.2.
  static final overline = _style(9, FontWeight.w800, letterSpacing: 1.2);

  /// Status badges ("Not Checked In", "Draft"). 9 / 13.5, ExtraBold.
  static final badge = _style(9, FontWeight.w800);

  /// Tiny uppercase tag ("LIVE"). 8 / 12, Bold, +1.
  static final micro = _style(8, FontWeight.w700, letterSpacing: 1);

  /// Character counters. 8 / 12, Regular.
  static final counter = _style(8, FontWeight.w400);

  /// "WorkTrack" wordmark next to the small logo. 13 / 19.5, ExtraBold, -0.2.
  static final brandWordmark = _style(13, FontWeight.w800, letterSpacing: -0.2);

  /// "WorkTrack" wordmark on auth screens. 22 / 33, ExtraBold, -0.6.
  static final brandWordmarkLarge = _style(
    22,
    FontWeight.w800,
    letterSpacing: -0.6,
  );
}
