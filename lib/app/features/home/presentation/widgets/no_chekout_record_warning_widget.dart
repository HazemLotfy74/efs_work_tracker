import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';

class NoChekoutRecordWarningWidget extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return CustomContainer(
      borderWidth: 1,
      containerColor: appColors.warningContainer,
      child: Row(
        spacing: 10,
        children: [
          Icon(Icons.warning_amber_outlined, color: appColors.warning),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                Text(
                  context.l10n.noEmployee,
                  style: AppTextStyles.itemTitle.copyWith(
                    color: appColors.warning,
                  ),
                ),
                Text(
                  context.l10n.noCheckout,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: appColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
