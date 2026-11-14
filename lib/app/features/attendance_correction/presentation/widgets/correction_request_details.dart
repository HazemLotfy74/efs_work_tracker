import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/utils/app_dimensions.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../domain/correction_rules.dart';
import '../../domain/entities/correction_request_entity.dart';

/// The proposed times and reason of one request and, once it is decided,
/// when it was decided and the reviewer's reason for the decision.
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
        if (request.status != CorrectionStatus.pending)
          _DecisionReason(request: request, note: note),
      ],
    );
  }
}

/// The reviewer's decision, set apart in the decision's own color.
class _DecisionReason extends StatelessWidget {
  const _DecisionReason({required this.request, required this.note});

  final CorrectionRequestEntity request;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final approved = request.status == CorrectionStatus.approved;
    final (background, foreground) =
        (approved ? AppMessageType.success : AppMessageType.error).colorsOf(
          context,
        );
    final decidedAt = request.reviewedAt;
    final note = this.note;
    return Container(
      key: const Key('decisionReason'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs,
        children: [
          Text(
            approved
                ? l10n.correctionApprovalReason
                : l10n.correctionRejectionReason,
            style: context.textTheme.labelLarge?.copyWith(color: foreground),
          ),
          Text(
            // Decisions made before a reason became mandatory have none.
            note == null || note.trim().isEmpty
                ? l10n.correctionNoDecisionReason
                : note,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          if (decidedAt != null)
            Text(
              l10n.correctionDecidedOn(
                '${decidedAt.formatShortDate(context)} ${decidedAt.formatTime(context)}',
              ),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
