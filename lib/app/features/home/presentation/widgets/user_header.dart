import 'package:efs_work_tracker/core/theme/app_theme_colors.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text_styles.dart';

class UserHeader extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final colorScheme = ColorScheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "WEDNESDAY  MAY 14",
              style: AppTextStyles.overline.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              "Good morning,",
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              "Mohamed",
              style: textTheme.headlineSmall?.copyWith(
                color: AppThemeColors.of(context).textHeading,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.surface),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: Offset(0, 5),
                color: colorScheme.shadow.withAlpha(20),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              "MH",
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
