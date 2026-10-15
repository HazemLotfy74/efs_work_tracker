import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
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
      icon: const SizedBox.square(
        dimension: 34,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.primary,
        ),
      ),
      iconBackgroundColor: AppColors.primarySoft,
      title: title,
      message: message,
    );
  }
}
