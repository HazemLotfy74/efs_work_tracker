import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';

class OverTimeRequestContainer extends StatelessWidget {
  const OverTimeRequestContainer({super.key});


  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      borderWidth: 1,
      child: Row(
        spacing: 10,
        children: [
          CustomContainer(
            horizontalPadding: 15,
            verticalPadding: 8,
            containerColor: context.colors.surfaceContainerLow,
            borderWidth: 1,
            child: Column(
              children: [
                Text(
                  '14',
                  style: context.textTheme.bodyMedium!.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "May",
                  style: context.textTheme.bodyMedium!.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              CustomStatusContainer(
                tone: StatusTone.success,
                text: context.l10n.approved,
              ),
              Text("4:00 pm , 5:00 Pm"),
            ],
          ),
        ],
      ),
    );
  }
}
