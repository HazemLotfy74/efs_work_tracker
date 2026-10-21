import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_status_container.dart';
import 'package:efs_work_tracker/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/custom_container.dart';

class AttendanceStatusDetailsContainer extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      containerColor: ColorScheme.of(context).onSurface,
      borderWidth: 1,
      child: Row(
        children: [
          Column(
            spacing: 5,
            children: [
              Text(
                'Wed',
                style: TextTheme.of(context).bodyMedium!
                    .copyWith(color: ColorScheme.of(context).onSurfaceVariant),
              ),
              Text(
                '14',
                style: TextTheme.of(context).bodyLarge!.copyWith(
                  color: ColorScheme.of(context).surface,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                ),
              ),
              Text(
                'May 2025',
                style: TextTheme.of(context).bodyMedium!
                    .copyWith(color: ColorScheme.of(context).onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(width: 10),
          Container(
            width: 1,
            height: 60,
            color: ColorScheme.of(context).onSurfaceVariant,
          ),
          SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              CustomStatusContainer(
                mainContainerColor: ColorScheme.of(context).secondaryContainer,
                statusContainerColor: ColorScheme.of(context)
                    .onSecondaryContainer,
                txtColor: ColorScheme.of(context).onSecondaryContainer,
                text: context.l10n.needsReview,
              ),
              Text(
                context.l10n.automaticClosed,
                style: TextTheme.of(context).bodyLarge!
                    .copyWith(color: ColorScheme.of(context).surface),
              ),
              Text(
                context.l10n.noEmployee,
                style: TextTheme.of(context).labelSmall!.copyWith(
                  color: AppColors.lightGreyColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
