import '../../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';
import '../../domain/entities/attendance_session_entity.dart';

/// Badge text and color for each [AttendanceDayStatus], in one place.
extension AttendanceDayStatusText on AttendanceDayStatus {
  String label(AppLocalizations l10n) => switch (this) {
    AttendanceDayStatus.inProgress => l10n.inProgress,
    AttendanceDayStatus.completed => l10n.checkedOut,
    AttendanceDayStatus.needsReview => l10n.needsReview,
  };

  StatusTone get tone => switch (this) {
    AttendanceDayStatus.inProgress => StatusTone.success,
    AttendanceDayStatus.completed => StatusTone.success,
    AttendanceDayStatus.needsReview => StatusTone.warning,
  };
}
