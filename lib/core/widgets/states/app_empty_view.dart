import 'package:flutter/material.dart';

import 'app_state_view.dart';

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    this.title = 'No attendance records',
    this.message = 'Your completed attendance sessions will appear here.',
    this.icon = Icons.event_note_outlined,
    this.actionLabel = 'Return to dashboard',
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppStateView(
      icon: AppStateIcon(icon),
      iconBackgroundColor: ColorScheme.of(context).primaryContainer,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
