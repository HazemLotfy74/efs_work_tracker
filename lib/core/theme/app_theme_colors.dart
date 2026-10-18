import 'package:flutter/material.dart';

/// Semantic colors that have no slot in Material's [ColorScheme].
///
/// Registered on both [AppTheme.light] and [AppTheme.dark]. Read them with
/// `AppThemeColors.of(context)`.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.textHeading,
    required this.fieldLabel,
    required this.navInactive,
    required this.attendanceCard,
    required this.onAttendanceCard,
    required this.onAttendanceCardMuted,
    required this.onAttendanceCardSubtle,
    required this.attendanceCardBadge,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.autoClosed,
  });

  /// Emphasised headings and names, darker than `onSurface`.
  final Color textHeading;

  /// Form field labels.
  final Color fieldLabel;

  /// Unselected bottom navigation labels.
  final Color navInactive;

  /// Background of the dark attendance card on the dashboard.
  final Color attendanceCard;

  /// Main text and icons on [attendanceCard], and its button background.
  final Color onAttendanceCard;

  /// Secondary text on [attendanceCard] ("Current local time").
  final Color onAttendanceCardMuted;

  /// Tertiary text and icons on [attendanceCard] (shift note).
  final Color onAttendanceCardSubtle;

  /// Status badge background on [attendanceCard].
  final Color attendanceCardBadge;

  /// Warning status (late, pending) background.
  final Color warningContainer;

  /// Text and icons on [warningContainer].
  final Color onWarningContainer;

  /// Attendance sessions closed automatically by the system.
  final Color autoClosed;

  static AppThemeColors of(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>()!;

  @override
  AppThemeColors copyWith({
    Color? textHeading,
    Color? fieldLabel,
    Color? navInactive,
    Color? attendanceCard,
    Color? onAttendanceCard,
    Color? onAttendanceCardMuted,
    Color? onAttendanceCardSubtle,
    Color? attendanceCardBadge,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? autoClosed,
  }) {
    return AppThemeColors(
      textHeading: textHeading ?? this.textHeading,
      fieldLabel: fieldLabel ?? this.fieldLabel,
      navInactive: navInactive ?? this.navInactive,
      attendanceCard: attendanceCard ?? this.attendanceCard,
      onAttendanceCard: onAttendanceCard ?? this.onAttendanceCard,
      onAttendanceCardMuted:
          onAttendanceCardMuted ?? this.onAttendanceCardMuted,
      onAttendanceCardSubtle:
          onAttendanceCardSubtle ?? this.onAttendanceCardSubtle,
      attendanceCardBadge: attendanceCardBadge ?? this.attendanceCardBadge,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      autoClosed: autoClosed ?? this.autoClosed,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      textHeading: Color.lerp(textHeading, other.textHeading, t)!,
      fieldLabel: Color.lerp(fieldLabel, other.fieldLabel, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      attendanceCard: Color.lerp(attendanceCard, other.attendanceCard, t)!,
      onAttendanceCard: Color.lerp(
        onAttendanceCard,
        other.onAttendanceCard,
        t,
      )!,
      onAttendanceCardMuted: Color.lerp(
        onAttendanceCardMuted,
        other.onAttendanceCardMuted,
        t,
      )!,
      onAttendanceCardSubtle: Color.lerp(
        onAttendanceCardSubtle,
        other.onAttendanceCardSubtle,
        t,
      )!,
      attendanceCardBadge: Color.lerp(
        attendanceCardBadge,
        other.attendanceCardBadge,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      autoClosed: Color.lerp(autoClosed, other.autoClosed, t)!,
    );
  }
}
