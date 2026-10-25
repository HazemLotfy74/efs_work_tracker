import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_status_container.dart';
import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';

class AttendanceStatusDetailsContainer extends StatelessWidget {
  const new({super.key, required this.date});

  /// Day of the attendance record.
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final textTheme = context.textTheme;
    final dateStyle = textTheme.bodyMedium?.copyWith(
      color: appColors.onBrandSurfaceMuted,
    );
    return CustomContainer(
      containerColor: appColors.brandSurface,
      borderColor: appColors.brandSurface,
      borderWidth: 1,
      child: Row(
        children: [
          Column(
            spacing: 5,
            children: [
              Text(date.formatWeekdayShort(context), style: dateStyle),
              Text(
                date.formatDayOfMonth(context),
                style: textTheme.displaySmall?.copyWith(
                  color: appColors.onBrandSurface,
                  fontSize: 30,
                ),
              ),
              Text(date.formatMonthYear(context), style: dateStyle),
            ],
          ),
          SizedBox(width: 10),
          Container(
            width: 1,
            height: 60,
            color: appColors.onBrandSurfaceSubtle,
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                CustomStatusContainer(
                  tone: StatusTone.warning,
                  text: context.l10n.needsReview,
                ),
                Text(
                  context.l10n.automaticClosed,
                  style: textTheme.bodyLarge?.copyWith(
                    color: appColors.onBrandSurface,
                  ),
                ),
                Text(
                  context.l10n.noEmployee,
                  style: AppTextStyles.meta.copyWith(
                    color: appColors.onBrandSurfaceSubtle,
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
