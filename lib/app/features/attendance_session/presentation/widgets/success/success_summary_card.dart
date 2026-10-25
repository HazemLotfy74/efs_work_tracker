import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../../core/widgets/custom_container.dart';

/// Small label, big value and the date, e.g.
/// "Confirmed at / 8:07 AM / Wednesday, May 14" or
/// "Final duration / 7h 19m / Wednesday, May 14".
class SuccessSummaryCard extends StatelessWidget {
  const SuccessSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.date,
  });

  final String label;
  final String value;
  final String date;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = AppTextStyles.meta.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return CustomContainer(
      containerWidth: double.infinity,
      verticalPadding: 17,
      borderWidth: 1,
      borderRadius: 22,
      child: Column(
        spacing: 4,
        children: [
          Text(label, style: mutedStyle),
          Text(
            value,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.headingText,
            ),
          ),
          Text(date, style: mutedStyle),
        ],
      ),
    );
  }
}
