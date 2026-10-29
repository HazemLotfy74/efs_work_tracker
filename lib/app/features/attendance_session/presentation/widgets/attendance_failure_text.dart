import '../../../../../core/errors/attendance_errors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Message shown to the user for each [AttendanceFailure].
extension AttendanceFailureText on AttendanceFailure {
  String message(AppLocalizations l10n) {
    return switch (this) {
      AttendanceFailure.accountNotReady => l10n.attendanceAccountNotReady,
      AttendanceFailure.noSchedule => l10n.attendanceNoSchedule,
      AttendanceFailure.notWorkingDay => l10n.attendanceNotWorkingDay,
      AttendanceFailure.checkInClosed => l10n.attendanceCheckInClosed,
      AttendanceFailure.alreadyCheckedIn => l10n.attendanceAlreadyCheckedIn,
      AttendanceFailure.notCheckedIn => l10n.attendanceNotCheckedIn,
      AttendanceFailure.alreadyCheckedOut => l10n.attendanceAlreadyCheckedOut,
      AttendanceFailure.closedAutomatically =>
        l10n.attendanceClosedAutomatically,
      AttendanceFailure.workDateChanged => l10n.attendanceWorkDateChanged,
      AttendanceFailure.invalidLocation => l10n.attendanceInvalidLocation,
      AttendanceFailure.selfieMissing => l10n.attendanceSelfieMissing,
      AttendanceFailure.selfieUploadFailed => l10n.attendanceSelfieUploadFailed,
      AttendanceFailure.busy => l10n.attendanceBusy,
      AttendanceFailure.outcomeUnknown => l10n.attendanceOutcomeUnknown,
      AttendanceFailure.network => l10n.saveAttendanceFailed,
      AttendanceFailure.serviceUnavailable => l10n.attendanceServiceUnavailable,
      AttendanceFailure.unknown => l10n.attendanceUnknownError,
    };
  }
}

/// The message for any error thrown while saving attendance.
String attendanceErrorMessage(Object error, AppLocalizations l10n) {
  final failure = error is AttendanceFailure
      ? error
      : AttendanceFailure.unknown;
  return failure.message(l10n);
}
