import 'package:flutter/material.dart';

import '../../theme/theme_context_extensions.dart';
import '../../utils/app_dimensions.dart';
import 'app_message_type.dart';

/// Shows [message] as the app's one SnackBar style: floating, with the
/// [type]'s icon and colors. The current SnackBar is replaced, so repeated
/// taps never stack messages. Long (Arabic) text wraps.
///
/// After an `await`, pass the [ScaffoldMessengerState] taken before it:
/// ```dart
/// final messenger = ScaffoldMessenger.of(context);
/// await save();
/// showAppSnackBar(messenger, l10n.saved, type: AppMessageType.success);
/// ```
void showAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  AppMessageType type = AppMessageType.info,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const Key('appSnackBar'),
        // The content draws the colors so they come from the messenger's
        // theme (light or dark).
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        elevation: 0,
        content: _AppSnackBarContent(message: message, type: type),
      ),
    );
}

class _AppSnackBarContent extends StatelessWidget {
  const _AppSnackBarContent({required this.message, required this.type});

  final String message;
  final AppMessageType type;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = type.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: foreground.withValues(alpha: 0.25)),
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Icon(type.icon, color: foreground, size: 22),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
