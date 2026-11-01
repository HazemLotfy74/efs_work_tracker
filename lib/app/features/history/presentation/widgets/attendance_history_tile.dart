import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/extensions/duration_format.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../attendance_correction/domain/correction_rules.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';

/// A navigable record row; data loading and filtering belong elsewhere.
class AttendanceHistoryTile extends StatelessWidget {
  const AttendanceHistoryTile({
    super.key,
    required this.session,
    this.first = true,
    this.last = true,
  });
  final AttendanceSessionEntity session;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final now = context.watch<ClockCubit>().state;
    final l10n = context.l10n;
    final date =
        session.workDate ??
        CorrectionRules.wallClock(session.timezone, session.checkInTime);
    final status = session.statusAt(now);
    final (label, tone) = switch (status) {
      AttendanceDayStatus.needsReview => (l10n.needsReview, StatusTone.error),
      AttendanceDayStatus.inProgress => (l10n.inProgress, StatusTone.success),
      _ when session.lateMinutes > 0 => (
        l10n.lateMinutes(session.lateMinutes),
        StatusTone.warning,
      ),
      _ => (l10n.onTime, StatusTone.success),
    };
    String time(DateTime value) =>
        CorrectionRules.wallClock(session.timezone, value).formatTime(context);
    final end = session.effectiveCheckOut ?? session.checkOutTime;
    final times =
        '${time(session.effectiveCheckIn ?? session.checkInTime)} → ${end == null ? '—' : time(end)}';
    final worked =
        session.durationAt(now)?.worked.formatHoursMinutes(context) ??
        l10n.notConfirmed;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final radius = BorderRadius.vertical(
      top: Radius.circular(first ? 20 : 0),
      bottom: Radius.circular(last ? 20 : 0),
    );
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.attendanceDetailsOf(session.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 350 ||
                  MediaQuery.textScalerOf(context).scale(14) > 18;
              return Row(
                children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      children: [
                        Text(
                          date.formatDayOfMonth(context),
                          style: context.textTheme.titleMedium,
                        ),
                        Text(date.formatWeekdayShort(context), style: muted),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomStatusContainer(
                          tone: tone,
                          text: label,
                          dense: true,
                        ),
                        const SizedBox(height: 4),
                        Text(times, style: context.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          l10n.officialShift(
                            time(
                              session.shift.startsAt ??
                                  session.shift.startOn(session.checkInTime),
                            ),
                            time(session.scheduledEnd),
                          ),
                          style: muted,
                        ),
                        if (compact) ...[
                          const SizedBox(height: 8),
                          Text(worked, style: context.textTheme.titleSmall),
                        ],
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    Text(worked, style: context.textTheme.titleSmall),
                  ],
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
