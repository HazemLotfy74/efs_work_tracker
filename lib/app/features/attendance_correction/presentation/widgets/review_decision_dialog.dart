import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/utils/app_dimensions.dart';
import '../../../../../core/widgets/feedback/app_dialog.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../domain/correction_rules.dart';

/// Confirms an approve or reject decision. Returns the trimmed note, or
/// `null` when cancelled.
///
/// With [reasonRequired] (every attendance correction decision) the note is
/// the decision's reason: it is labelled as such, [details] shows the request
/// being decided, and the confirm button stays disabled until something is
/// written. The database refuses a decision without one as well.
Future<String?> showReviewDecisionDialog(
  BuildContext context, {
  required bool approve,
  required String title,
  required String message,
  bool reasonRequired = false,
  Widget? details,
}) => showDialog<String>(
  context: context,
  builder: (_) => _ReviewDecisionDialog(
    approve: approve,
    title: title,
    message: message,
    reasonRequired: reasonRequired,
    details: details,
  ),
);

class _ReviewDecisionDialog extends StatefulWidget {
  const _ReviewDecisionDialog({
    required this.approve,
    required this.title,
    required this.message,
    required this.reasonRequired,
    required this.details,
  });

  final bool approve;
  final String title;
  final String message;
  final bool reasonRequired;
  final Widget? details;

  @override
  State<_ReviewDecisionDialog> createState() => _ReviewDecisionDialogState();
}

class _ReviewDecisionDialogState extends State<_ReviewDecisionDialog> {
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Enables the confirm button once a reason is written.
    if (widget.reasonRequired) _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final approve = widget.approve;
    final required = widget.reasonRequired;
    final details = widget.details;
    final ready = !required || _note.text.trim().isNotEmpty;
    return AppDialog(
      title: widget.title,
      message: widget.message,
      type: approve ? AppMessageType.success : AppMessageType.error,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          ?details,
          TextField(
            key: const Key('reviewNote'),
            controller: _note,
            maxLines: 3,
            maxLength: CorrectionRules.maxTextLength,
            textInputAction: TextInputAction.newline,
            decoration: required
                ? InputDecoration(
                    labelText: approve
                        ? l10n.correctionApprovalReason
                        : l10n.correctionRejectionReason,
                    hintText: approve
                        ? l10n.correctionApprovalReasonHint
                        : l10n.correctionRejectionReasonHint,
                    helperText: l10n.correctionDecisionReasonRequired,
                    helperMaxLines: 2,
                    alignLabelWithHint: true,
                  )
                : InputDecoration(hintText: l10n.correctionNoteOptional),
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: l10n.correctionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialogAction(
          key: const Key('confirmReview'),
          label: switch ((required, approve)) {
            (true, true) => l10n.correctionConfirmApprove,
            (true, false) => l10n.correctionConfirmReject,
            (false, true) => l10n.correctionApprove,
            (false, false) => l10n.correctionReject,
          },
          primary: true,
          destructive: !approve,
          onPressed: ready
              ? () => Navigator.of(context).pop(_note.text.trim())
              : null,
        ),
      ],
    );
  }
}
