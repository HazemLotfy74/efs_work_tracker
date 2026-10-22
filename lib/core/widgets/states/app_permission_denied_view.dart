import 'package:flutter/material.dart';

import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';

import 'app_state_view.dart';

class AppPermissionDeniedView extends StatelessWidget {
  const AppPermissionDeniedView({
    super.key,
    this.title = 'Location permission needed',
    this.message =
        'Allow precise location access to securely record your attendance.',
    this.note =
        'WorkTrack captures location only when you check in or check out.',
    this.icon = Icons.location_off_outlined,
    this.onOpenSettings,
  });

  final String title;
  final String message;
  final String? note;
  final IconData icon;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    return AppStateView(
      icon: AppStateIcon(icon, color: colorScheme.error),
      iconBackgroundColor: colorScheme.errorContainer,
      title: title,
      message: message,
      note: note,
      actionLabel: 'Open device settings',
      onAction: onOpenSettings,
    );
  }
}
