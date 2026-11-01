import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/feedback/app_dialog.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../domain/correction_rules.dart';

/// Confirms an approve or reject decision and takes an optional note.
/// Returns the note (possibly empty), or `null` when cancelled.
Future<String?> showReviewDecisionDialog(
  BuildContext context, {
  required bool approve,
  required String title,
  required String message,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _ReviewDecisionDialog(approve: approve, title: title, message: message),
);

class _ReviewDecisionDialog extends StatefulWidget {
  const _ReviewDecisionDialog({
    required this.approve,
    required this.title,
    required this.message,
  });

  final bool approve;
  final String title;
  final String message;

  @override
  State<_ReviewDecisionDialog> createState() => _ReviewDecisionDialogState();
}

class _ReviewDecisionDialogState extends State<_ReviewDecisionDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final approve = widget.approve;
    return AppDialog(
      title: widget.title,
      message: widget.message,
      type: approve ? AppMessageType.success : AppMessageType.error,
      content: TextField(
        key: const Key('reviewNote'),
        controller: _note,
        maxLines: 3,
        maxLength: CorrectionRules.maxTextLength,
        decoration: InputDecoration(hintText: l10n.correctionNoteOptional),
      ),
      actions: [
        AppDialogAction(
          label: l10n.correctionCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialogAction(
          key: const Key('confirmReview'),
          label: approve ? l10n.correctionApprove : l10n.correctionReject,
          primary: true,
          destructive: !approve,
          onPressed: () => Navigator.of(context).pop(_note.text),
        ),
      ],
    );
  }
}
