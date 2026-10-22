import 'package:flutter/material.dart';

import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';

import 'app_state_view.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    this.title = 'Couldn’t load your data',
    this.message =
        'Check your connection and try again. Your saved attendance is safe.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    return AppStateView(
      icon: AppStateIcon(Icons.warning_amber_rounded, color: colorScheme.error),
      iconBackgroundColor: colorScheme.errorContainer,
      title: title,
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}
