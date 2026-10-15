import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
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
    return AppStateView(
      icon: const AppStateIcon(
        Icons.warning_amber_rounded,
        color: AppColors.error,
      ),
      iconBackgroundColor: AppColors.errorSoft,
      title: title,
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}
