import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/extensions/duration_format.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../attendance_session/presentation/widgets/attendance_day_status_text.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';

/// The badge and one line of detail for an attendance day, as an admin
/// sees it. A session still running after its shift end is flagged: it
/// may have been forgotten, and the server closes it at the deadline.
class AdminDayStatus extends StatelessWidget {
  const AdminDayStatus({super.key, required this.session, required this.now});

  final AttendanceSessionEntity session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = session.statusAt(now);
    final pastShiftEnd =
        status == AttendanceDayStatus.inProgress &&
        !now.isBefore(session.scheduledEnd);
    final (tone, label) = pastShiftEnd
        ? (StatusTone.warning, l10n.adminPastShiftEnd)
        : (status.tone, status.label(l10n));
    final worked = session.durationAt(now)?.worked;
    final out = session.checkOutTime;
    final detail = [
      status == AttendanceDayStatus.inProgress
          ? l10n.adminSince(session.checkInTime.formatTime(context))
          : session.checkInTime.formatTime(context),
      if (out != null) out.formatTime(context),
      if (status != AttendanceDayStatus.inProgress)
        worked?.formatHoursMinutes(context) ?? l10n.notConfirmed,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 4,
      children: [
        CustomStatusContainer(tone: tone, text: label),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
