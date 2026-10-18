import 'package:flutter/material.dart';

import '../app_primary_button.dart';

/// Base layout for full-screen loading, empty, error and permission states.
///
/// Wrap it in a [Scaffold] with an app bar on the screen that shows it.
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.message,
    this.note,
    this.actionLabel,
    this.onAction,
  });

  final Widget icon;
  final Color iconBackgroundColor;
  final String title;
  final String message;
  final String? note;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 80, 28, 36),
        child: Column(
          children: [
            Container(
              width: 86,
              height: 86,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: icon,
            ),
            const SizedBox(height: 23),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextTheme.of(context).headlineMedium,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextTheme.of(context).bodyMedium
                    ?.copyWith(color: ColorScheme.of(context).onSurfaceVariant),
              ),
            ),
            const Spacer(),
            if (note != null) ...[
              Text(
                note!,
                textAlign: TextAlign.center,
                style: TextTheme.of(context).bodyMedium
                    ?.copyWith(color: ColorScheme.of(context).onSurfaceVariant),
              ),
              const SizedBox(height: 16),
            ],
            if (actionLabel != null)
              AppPrimaryButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

/// Icon sized for [AppStateView].
class AppStateIcon extends StatelessWidget {
  const AppStateIcon(this.icon, {super.key, this.color});

  final IconData icon;

  /// Defaults to the theme's primary color.
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: 34, color: color ?? ColorScheme.of(context).primary);
}
