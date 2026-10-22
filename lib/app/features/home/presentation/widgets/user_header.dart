import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/app_text_styles.dart';

class UserHeader extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colors;
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
              context.l10n.goodMorning,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              "Mohamed",
              style: textTheme.headlineSmall?.copyWith(
                color: context.appColors.headingText,
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
