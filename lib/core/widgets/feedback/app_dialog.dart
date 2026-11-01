import 'package:flutter/material.dart';

import '../../theme/theme_context_extensions.dart';
import '../../utils/app_dimensions.dart';
import 'app_message_type.dart';

/// The app's one dialog style: an icon in the [type]'s colors, a title, a
/// message, optional [content] (e.g. a note field) and [actions]. Scrolls
/// when long text (or the keyboard) leaves too little room.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.type = AppMessageType.info,
    required this.actions,
  });

  final String title;
  final String? message;
  final Widget? content;
  final AppMessageType type;

  /// Usually [AppDialogAction]s; the last one is the main action.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = type.colorsOf(context);
    final message = this.message;
    final content = this.content;
    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(type.icon, color: foreground, size: 28),
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.md,
          children: [
            if (message != null) Text(message, textAlign: TextAlign.center),
            ?content,
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: actions,
    );
  }
}

/// A dialog button: the main action filled in the dialog's tone, the
/// others as text buttons.
class AppDialogAction extends StatelessWidget {
  const AppDialogAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  /// Uses the error color (reject, delete).
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (!primary) {
      return TextButton(onPressed: onPressed, child: Text(label));
    }
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: destructive ? colors.error : colors.primary,
        foregroundColor: destructive ? colors.onError : colors.onPrimary,
        minimumSize: const Size(96, 44),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// Asks the user to confirm; `true` only when they chose [confirmLabel].
Future<bool> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  required String cancelLabel,
  AppMessageType type = AppMessageType.warning,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: title,
      message: message,
      type: type,
      actions: [
        AppDialogAction(
          label: cancelLabel,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppDialogAction(
          key: const Key('confirmDialog'),
          label: confirmLabel,
          primary: true,
          destructive: destructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
