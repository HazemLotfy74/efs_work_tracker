import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_status_container.dart';
import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../attendance_session/presentation/widgets/attendance_day_status_text.dart';

/// Date and status at the top of an attendance day's details.
class AttendanceStatusDetailsContainer extends StatelessWidget {
  const new({super.key, required this.session, required this.status});

  final AttendanceSessionEntity session;
  final AttendanceDayStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appColors = context.appColors;
    final textTheme = context.textTheme;
    final date = session.workDate ?? session.checkInTime;
    final (title, subtitle) = switch (status) {
      AttendanceDayStatus.inProgress => (
        l10n.checkedIn,
        l10n.elapsedWorkingTime,
      ),
      AttendanceDayStatus.completed => (l10n.checkedOut, null),
      AttendanceDayStatus.needsReview => (
        l10n.automaticClosed,
        l10n.noEmployee,
      ),
    };
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
                  tone: status.tone,
                  text: status.label(l10n),
                ),
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    color: appColors.onBrandSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
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
