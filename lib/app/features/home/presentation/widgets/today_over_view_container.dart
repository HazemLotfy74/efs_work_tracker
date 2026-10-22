import 'package:efs_work_tracker/core/theme/app_text_styles.dart';
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';

class TodayOverViewContainer extends StatelessWidget {
  const TodayOverViewContainer({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    this.containerColor,
  });

  final double width;
  final String label;
  final String value;
  final Color? containerColor;
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 75.5),
      child: CustomContainer(
        containerWidth: width,
        borderWidth: 1,
        containerColor: containerColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.meta.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            Text(value, style: context.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
