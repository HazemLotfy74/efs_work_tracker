import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_status_container.dart';
import 'package:efs_work_tracker/core/widgets/text_icon_widget.dart';
import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/custom_container.dart';

class AttendanceEventWidget extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 15,
        children: [
          Text(
            context.l10n.attendanceEvents,
            style: TextTheme.of(context).bodyLarge!
                .copyWith(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              CustomContainer(
                borderWidth: 1,
                containerColor: ColorScheme.of(context).onPrimary,
                child: Icon(
                  Icons.work_outline,
                  color: ColorScheme.of(context).primary,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomStatusContainer(
                    mainContainerColor: ColorScheme.of(context).onPrimary,
                    statusContainerColor: ColorScheme.of(context).primary,
                    txtColor: ColorScheme.of(context).primary,
                    text: context.l10n.withinGracePeriod,
                  ),
                  Text(
                    "${context.l10n.checkIn}. 8:07 Am",
                    style: TextTheme.of(context).bodyMedium,
                  ),
                  TextIconWidget(
                    txt: "التجمع الخامس",
                    icon: Icons.location_on_outlined,
                    style: TextTheme.of(context).bodyMedium!,
                    iconColor: Colors.grey,
                    iconSize: 20,
                  ),
                  Text(
                    context.l10n.selfieAndGps,
                    style: TextTheme.of(context).bodyMedium,
                  ),
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
                containerColor: ColorScheme.of(context).secondaryContainer,
                child: Icon(
                  Icons.access_time,
                  color: ColorScheme.of(context).onSecondaryContainer,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  CustomStatusContainer(
                    mainContainerColor: ColorScheme.of(context)
                        .secondaryContainer,
                    statusContainerColor: ColorScheme.of(context)
                        .onSecondaryContainer,
                    txtColor: ColorScheme.of(context).onSecondaryContainer,
                    text: context.l10n.systemGenerated,
                  ),
                  Text(
                    "${context.l10n.autoClosed}. 8:07 Am",
                    style: TextTheme.of(context).bodyMedium,
                  ),
                  TextIconWidget(
                    txt: context.l10n.noLocationOrSelfie,
                    icon: Icons.location_on_outlined,
                    style: TextTheme.of(context).bodyMedium!,
                    iconColor: Colors.grey,
                    iconSize: 15,
                  ),
                  Text(
                    context.l10n.flaggedForAdmin,
                    style: TextTheme.of(context).bodyMedium,
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
