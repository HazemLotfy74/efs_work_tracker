import 'package:efs_work_tracker/app/features/home/presentation/widgets/text_icon_widget.dart';
import 'package:efs_work_tracker/core/constants/constants.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:efs_work_tracker/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/custom_box_shadow.dart';

class NotCheckedInCustomContainer extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        color: getColors(context).attendanceCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          customBoxShadow(
            blur: 32,
            x: 0,
            y: 18,
            color: ColorScheme.of(context).shadow.withAlpha(10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                decoration: BoxDecoration(
                  color: getColors(context).attendanceCardBadge,
                  borderRadius: BorderRadius.circular(12.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 5,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      decoration: BoxDecoration(
                        color: getColors(context).onAttendanceCard,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      context.l10n.notCheckedIn,
                      style: AppTextStyles.badge.copyWith(
                        color: getColors(context).onAttendanceCard,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            "4:48",
            style: getTextTheme(context).displaySmall?.copyWith(
              color: getColors(context).onAttendanceCard,
            ),
          ),
          Text(
            context.l10n.currentLocalTime,
            style: getTextTheme(context).bodySmall?.copyWith(
              color: getColors(context).onAttendanceCardMuted,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            onPressed: () {},
            bgColor: getColors(context).onAttendanceCard,
            child: TextIconWidget(
              txt: context.l10n.checkInNow,
              icon: Icons.camera_alt_outlined,
              style: getTextTheme(context).labelLarge!.copyWith(
                color: getColors(context).attendanceCard,
              ),
              iconColor: getColors(context).attendanceCard,
              iconSize: 24,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          TextIconWidget(
            txt: context.l10n.officialShift("8:00", "4:00"),
            icon: Icons.work_history_outlined,
            style: getTextTheme(context).bodySmall!.copyWith(
              color: getColors(context).onAttendanceCardSubtle,
            ),
            iconColor: getColors(context).onAttendanceCardSubtle,
            iconSize: 16,
          ),
        ],
      ),
    );
  }
}
