import 'package:flutter/material.dart';

import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';

import 'app_state_view.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    this.title = 'Loading attendance',
    this.message = 'Syncing your latest records and approvals.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppStateView(
      // CircularProgressIndicator uses the theme's primary color by default.
      icon: const SizedBox.square(
        dimension: 34,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
      iconBackgroundColor: context.colors.primaryContainer,
      title: title,
      message: message,
    );
  }
}
