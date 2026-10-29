import 'package:efs_work_tracker/app/features/home/presentation/widgets/today_over_view_container.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/extensions/duration_format.dart';
import 'package:flutter/material.dart';

import '../../../attendance_session/domain/entities/attendance_session_entity.dart';

/// Recorded time, lateness, early leave and approved overtime of one day.
/// Unknown values show "-", never a made-up zero.
class CustomWorkSummaryWidget extends StatelessWidget {
  const CustomWorkSummaryWidget({
    super.key,
    required this.spacing,
    required this.itemWidth,
    this.containerColor,
    this.session,
    required this.now,
  });

  final double spacing;
  final double itemWidth;
  final Color? containerColor;

  /// `null` before check-in.
  final AttendanceSessionEntity? session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = this.session;
    final worked = session?.durationAt(now);
    final String recorded;
    if (session == null) {
      recorded = '-';
    } else if (worked == null) {
      recorded = l10n.notConfirmed;
    } else {
      recorded = worked.regular.formatHoursMinutes(context);
    }
    // Automatic: worked time beyond 8 hours. Unknown (`-`) while the hours
    // of a closed day are not confirmed.
    final overtime = worked?.overtime;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        TodayOverViewContainer(
          width: itemWidth,
          label: worked == null ? l10n.recorded : l10n.regularHours,
          value: recorded,
          containerColor: containerColor,
        ),
        TodayOverViewContainer(
          width: itemWidth,
          label: l10n.lateness,
          value: session == null
              ? '-'
              : Duration(minutes: session.lateMinutes)
                    .formatHoursMinutes(context),
          containerColor: containerColor,
        ),
        TodayOverViewContainer(
          width: itemWidth,
          label: l10n.earlyLeave,
          value: session == null || !session.isVerified
              ? '-'
              : session.earlyLeave.formatHoursMinutes(context),
          containerColor: containerColor,
        ),
        TodayOverViewContainer(
          width: itemWidth,
          label: l10n.approvedOT,
          value: overtime?.formatHoursMinutes(context) ?? '-',
          containerColor: containerColor,
        ),
      ],
    );
  }
}
