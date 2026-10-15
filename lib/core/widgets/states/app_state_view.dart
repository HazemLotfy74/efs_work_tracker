import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
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
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
            ),
            const Spacer(),
            if (note != null) ...[
              Text(
                note!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
            if (actionLabel != null)
              AppPrimaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

/// Icon sized for [AppStateView].
class AppStateIcon extends StatelessWidget {
  const AppStateIcon(this.icon, {super.key, this.color = AppColors.primary});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(icon, size: 34, color: color);
}
