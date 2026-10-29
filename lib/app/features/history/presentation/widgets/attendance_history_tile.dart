import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/extensions/duration_format.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../attendance_session/presentation/widgets/attendance_day_status_text.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';

/// One day in History: date, status, times and worked time. Opens the
/// day's details.
class AttendanceHistoryTile extends StatelessWidget {
  const AttendanceHistoryTile({super.key, required this.session});

  final AttendanceSessionEntity session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = context.watch<ClockCubit>().state;
    final status = session.statusAt(now);
    final worked = session.durationAt(now)?.worked;
    final date = session.workDate ?? session.checkInTime;
    final out = session.checkOutTime;
    final muted = AppTextStyles.meta.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return CustomContainer(
      borderWidth: 1,
      onTap: () => context.push(AppRoutes.attendanceDetailsOf(session.id)),
      child: Row(
        spacing: 14,
        children: [
          Column(
            spacing: 2,
            children: [
              Text(date.formatWeekdayShort(context), style: muted),
              Text(
                date.formatDayOfMonth(context),
                style: context.textTheme.titleLarge,
              ),
              Text(date.formatMonthYear(context), style: muted),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                CustomStatusContainer(
                  tone: status.tone,
                  text: status.label(l10n),
                ),
                Text(
                  '${session.checkInTime.formatTime(context)} – '
                  '${out?.formatTime(context) ?? '--'}',
                  style: AppTextStyles.itemTitle,
                ),
                Text(
                  worked?.formatHoursMinutes(context) ?? l10n.notConfirmed,
                  style: muted,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
        ],
      ),
    );
  }
}
