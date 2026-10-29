import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../domain/correction_rules.dart';
import '../../domain/entities/correction_request_entity.dart';

/// The proposed times and reason of one request, and the reviewer's note.
/// Times are shown in the day's [timezone] (company time).
class CorrectionRequestDetails extends StatelessWidget {
  const CorrectionRequestDetails({
    super.key,
    required this.request,
    required this.timezone,
  });

  final CorrectionRequestEntity request;
  final String? timezone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String time(DateTime instant) =>
        CorrectionRules.wallClock(timezone, instant).formatTime(context);
    final checkOut = request.proposedCheckOut;
    final note = request.reviewNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        InfoRow(
          label: l10n.correctionCheckIn,
          value: time(request.proposedCheckIn),
        ),
        InfoRow(
          label: l10n.correctionCheckOut,
          value: checkOut == null ? '--' : time(checkOut),
        ),
        Text(
          '${l10n.correctionReason}: ${request.reason}',
          style: context.textTheme.bodyMedium,
        ),
        if (note != null)
          Text(
            '${l10n.correctionReviewNote}: $note',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
