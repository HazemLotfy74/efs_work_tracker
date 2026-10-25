import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/attendance_type.dart';

/// Every text that differs between check-in and check-out, in one place.
/// The screens ask for `type.title(l10n)` instead of choosing themselves.
extension AttendanceTypeText on AttendanceType {
  /// App bar title: "Check in" / "Check out".
  String title(AppLocalizations l10n) => switch (this) {
    AttendanceType.checkIn => l10n.checkInPage,
    AttendanceType.checkOut => l10n.checkOutPage,
  };

  /// Review row label: "Check-in time" / "Check-out time".
  String timeLabel(AppLocalizations l10n) => switch (this) {
    AttendanceType.checkIn => l10n.checkInTime,
    AttendanceType.checkOut => l10n.checkOutTime,
  };

  /// Review button: "Confirm check-in" / "Confirm check-out".
  String confirmLabel(AppLocalizations l10n) => switch (this) {
    AttendanceType.checkIn => l10n.confirmCheckIn,
    AttendanceType.checkOut => l10n.confirmCheckOut,
  };

  /// Badge once done: "Checked In" / "Checked Out".
  String doneLabel(AppLocalizations l10n) => switch (this) {
    AttendanceType.checkIn => l10n.checkedIn,
    AttendanceType.checkOut => l10n.checkedOut,
  };

  /// Success screen title: "You're all set!" / "Workday recorded".
  String successTitle(AppLocalizations l10n) => switch (this) {
    AttendanceType.checkIn => l10n.youAreAllSet,
    AttendanceType.checkOut => l10n.workdayRecorded,
  };
}
