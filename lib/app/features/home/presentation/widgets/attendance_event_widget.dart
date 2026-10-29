import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_status_container.dart';
import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../attendance_session/domain/entities/attendance_event_entity.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';

/// The day's events: the check-in, then the employee's check-out or the
/// server's automatic close (which has no evidence and needs review).
class AttendanceEventWidget extends StatelessWidget {
  const new({super.key, required this.session, required this.status});

  final AttendanceSessionEntity session;
  final AttendanceDayStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final appColors = context.appColors;
    final textTheme = context.textTheme;
    final checkOut = session.checkOut;

    return CustomContainer(
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 15,
        children: [
          Text(l10n.attendanceEvents, style: textTheme.titleMedium),
          _EventRow(
            icon: Icons.work_outline,
            iconColor: colors.primary,
            iconBackground: colors.primaryContainer,
            tone: session.lateMinutes > 0
                ? StatusTone.warning
                : StatusTone.success,
            badge: session.lateMinutes > 0
                ? l10n.lateMinutes(session.lateMinutes)
                : l10n.onTime,
            title:
                '${l10n.checkIn}. ${session.checkInTime.formatTime(context)}',
            event: session.checkIn,
          ),
          if (checkOut != null)
            _EventRow(
              icon: Icons.logout,
              iconColor: colors.primary,
              iconBackground: colors.primaryContainer,
              tone: StatusTone.success,
              badge: l10n.checkedOut,
              title:
                  '${l10n.checkOutTime}. ${checkOut.time!.formatTime(context)}',
              event: checkOut,
            )
          else if (status == AttendanceDayStatus.needsReview)
            _EventRow(
              icon: Icons.access_time,
              iconColor: appColors.warning,
              iconBackground: appColors.warningContainer,
              tone: StatusTone.warning,
              badge: l10n.systemGenerated,
              title:
                  '${l10n.autoClosed}. '
                  '${(session.autoClosedAt ?? session.closeDeadline).formatTime(context)}',
              note: l10n.flaggedForAdmin,
            ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.tone,
    required this.badge,
    required this.title,
    this.event,
    this.note,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final StatusTone tone;
  final String badge;
  final String title;

  /// The employee's evidence; `null` for a system event.
  final AttendanceEventEntity? event;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = context.textTheme;
    final appColors = context.appColors;
    final location = event?.location;
    final hasEvidence = location != null && event?.selfiePath != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        CustomContainer(
          borderWidth: 1,
          containerColor: iconBackground,
          child: Icon(icon, color: iconColor),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              CustomStatusContainer(tone: tone, text: badge),
              Text(title, style: textTheme.bodyMedium),
              // Wraps instead of overflowing with long text or large fonts.
              Row(
                spacing: 6,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: appColors.secondaryIcon,
                    size: 18,
                  ),
                  Expanded(
                    child: Text(
                      location == null
                          ? l10n.noLocationOrSelfie
                          : l10n.verifiedAccuracy(
                              location.accuracyMeters.round(),
                            ),
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              Text(
                note ??
                    (hasEvidence ? l10n.selfieAndGps : l10n.noLocationOrSelfie),
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
