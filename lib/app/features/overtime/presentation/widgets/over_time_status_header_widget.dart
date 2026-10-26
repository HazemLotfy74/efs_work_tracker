import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extensions.dart';

class OverTimeStatusHeaderWidget extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: CustomContainer(
            horizontalPadding: 17,
            verticalPadding: 17,
            containerColor: context.colors.onSurface,
            borderWidth: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  context.l10n.approvedThisMonth,
                  style: context.textTheme.bodySmall!.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "3H 15M",
                  style: context.textTheme.bodyLarge!.copyWith(
                    color: context.colors.surface,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: CustomContainer(
            horizontalPadding: 17,
            verticalPadding: 17,
            containerColor: context.colors.surface,
            borderWidth: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  context.l10n.pendingDecision,
                  style: context.textTheme.bodySmall!.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                Text(
                  "3H 15M",
                  style: context.textTheme.bodyLarge!.copyWith(
                    color: context.colors.onSurface,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
