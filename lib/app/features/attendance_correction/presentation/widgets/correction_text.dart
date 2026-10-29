import '../../../../../core/errors/correction_errors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';
import '../../domain/entities/correction_request_entity.dart';

/// Message shown to the user for each [CorrectionFailure].
extension CorrectionFailureText on CorrectionFailure {
  String message(AppLocalizations l10n) {
    return switch (this) {
      CorrectionFailure.notAllowed => l10n.correctionNotAllowed,
      CorrectionFailure.ownRequest => l10n.correctionOwnRequest,
      CorrectionFailure.notFound => l10n.correctionNotFound,
      CorrectionFailure.notClosed => l10n.correctionNotClosed,
      CorrectionFailure.invalidTimes => l10n.correctionInvalidTimes,
      CorrectionFailure.missingCheckOut => l10n.correctionMissingCheckOut,
      CorrectionFailure.invalidReason => l10n.correctionInvalidReason,
      CorrectionFailure.noteTooLong => l10n.correctionNoteTooLong,
      CorrectionFailure.noChange => l10n.correctionNoChange,
      CorrectionFailure.alreadyPending => l10n.correctionAlreadyPending,
      CorrectionFailure.alreadyReviewed => l10n.correctionAlreadyReviewed,
      CorrectionFailure.attendanceChanged => l10n.correctionAttendanceChanged,
      CorrectionFailure.busy => l10n.correctionBusy,
      CorrectionFailure.network => l10n.correctionNetwork,
      CorrectionFailure.serviceUnavailable => l10n.correctionServiceUnavailable,
      CorrectionFailure.unknown => l10n.correctionUnknownError,
    };
  }
}

/// Badge text and tone for each [CorrectionStatus].
extension CorrectionStatusText on CorrectionStatus {
  String label(AppLocalizations l10n) => switch (this) {
    CorrectionStatus.pending => l10n.pendingApproval,
    CorrectionStatus.approved => l10n.approved,
    CorrectionStatus.rejected => l10n.rejected,
  };

  StatusTone get tone => switch (this) {
    CorrectionStatus.pending => StatusTone.warning,
    CorrectionStatus.approved => StatusTone.success,
    CorrectionStatus.rejected => StatusTone.error,
  };
}
