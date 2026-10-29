import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
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
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text(widget.message),
            TextField(
              key: const Key('reviewNote'),
              controller: _note,
              maxLines: 3,
              maxLength: CorrectionRules.maxTextLength,
              decoration: InputDecoration(
                hintText: l10n.correctionNoteOptional,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.correctionCancel),
        ),
        TextButton(
          key: const Key('confirmReview'),
          style: approve
              ? null
              : TextButton.styleFrom(foregroundColor: context.colors.error),
          onPressed: () => Navigator.of(context).pop(_note.text),
          child: Text(approve ? l10n.correctionApprove : l10n.correctionReject),
        ),
      ],
    );
  }
}
