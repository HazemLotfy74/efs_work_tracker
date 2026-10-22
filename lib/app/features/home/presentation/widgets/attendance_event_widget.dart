import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_status_container.dart';
import 'package:efs_work_tracker/core/widgets/text_icon_widget.dart';
import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';

class AttendanceEventWidget extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final appColors = context.appColors;
    final textTheme = context.textTheme;
    return CustomContainer(
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 15,
        children: [
          Text(context.l10n.attendanceEvents, style: textTheme.titleMedium),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              CustomContainer(
                borderWidth: 1,
                containerColor: colors.primaryContainer,
                child: Icon(Icons.work_outline, color: colors.primary),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomStatusContainer(
                    tone: StatusTone.success,
                    text: context.l10n.withinGracePeriod,
                  ),
                  Text(
                    "${context.l10n.checkIn}. 8:07 Am",
                    style: textTheme.bodyMedium,
                  ),
                  TextIconWidget(
                    txt: "التجمع الخامس",
                    icon: Icons.location_on_outlined,
                    style: textTheme.bodyMedium!,
                    iconColor: appColors.secondaryIcon,
                    iconSize: 20,
                  ),
                  Text(context.l10n.selfieAndGps, style: textTheme.bodyMedium),
                ],
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              CustomContainer(
                borderWidth: 1,
                containerColor: appColors.warningContainer,
                child: Icon(Icons.access_time, color: appColors.warning),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  CustomStatusContainer(
                    tone: StatusTone.warning,
                    text: context.l10n.systemGenerated,
                  ),
                  Text(
                    "${context.l10n.autoClosed}. 8:07 Am",
                    style: textTheme.bodyMedium,
                  ),
                  TextIconWidget(
                    txt: context.l10n.noLocationOrSelfie,
                    icon: Icons.location_on_outlined,
                    style: textTheme.bodyMedium!,
                    iconColor: appColors.secondaryIcon,
                    iconSize: 15,
                  ),
                  Text(
                    context.l10n.flaggedForAdmin,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
