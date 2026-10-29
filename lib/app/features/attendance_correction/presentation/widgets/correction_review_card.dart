import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../domain/correction_rules.dart';
import '../../domain/entities/correction_request_entity.dart';
import '../manager/pending_corrections_cubit/pending_corrections_cubit.dart';
import 'correction_request_details.dart';
import 'correction_text.dart';
import 'review_decision_dialog.dart';

/// One pending request in the admin's queue, with Approve and Reject.
class CorrectionReviewCard extends StatelessWidget {
  const CorrectionReviewCard({
    super.key,
    required this.request,
    required this.reviewing,
  });

  final CorrectionRequestEntity request;

  /// Its review is being sent.
  final bool reviewing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final workDate = request.workDate;
    final actualCheckIn = request.actualCheckIn;
    final code = request.employeeCode;
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 16,
      verticalPadding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text(
            [?request.employeeName, ?code].join(' · '),
            style: context.textTheme.titleMedium,
          ),
          if (workDate != null)
            Text(
              workDate.formatFullDate(context),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          if (actualCheckIn != null)
            InfoRow(
              label: l10n.correctionRecordedCheckIn,
              value: CorrectionRules.wallClock(
                request.timezone,
                actualCheckIn,
              ).formatTime(context),
            ),
          const Divider(),
          Text(
            l10n.correctionProposedTimes,
            style: context.textTheme.labelMedium,
          ),
          CorrectionRequestDetails(
            request: request,
            timezone: request.timezone,
          ),
          if (reviewing)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('reject-${request.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.error,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: () => _review(context, approve: false),
                    child: Text(l10n.correctionReject),
                  ),
                ),
                Expanded(
                  child: AppPrimaryButton(
                    key: Key('approve-${request.id}'),
                    onPressed: () => _review(context, approve: true),
                    child: Text(l10n.correctionApprove),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _review(BuildContext context, {required bool approve}) async {
    final l10n = context.l10n;
    final cubit = context.read<PendingCorrectionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final note = await showReviewDecisionDialog(
      context,
      approve: approve,
      title: approve ? l10n.correctionApproveTitle : l10n.correctionRejectTitle,
      message: approve
          ? l10n.correctionApproveMessage
          : l10n.correctionRejectMessage,
    );
    if (note == null) return;
    final failure = await cubit.review(
      request.id,
      approve: approve,
      note: note,
    );
    final text = failure == null
        ? (approve ? l10n.correctionApprovedDone : l10n.correctionRejectedDone)
        : failure.message(l10n);
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }
}
