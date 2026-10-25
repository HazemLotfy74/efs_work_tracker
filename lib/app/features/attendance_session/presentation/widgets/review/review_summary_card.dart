import 'package:flutter/material.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../../../../../core/extensions/date_time_format.dart';
import '../../../../../../core/extensions/duration_format.dart';
import '../../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../../core/widgets/custom_container.dart';
import '../../../domain/entities/attendance_event_entity.dart';
import '../../../domain/entities/attendance_session_entity.dart';
import '../../../domain/entities/attendance_type.dart';
import '../attendance_type_text.dart';
import 'summary_row.dart';

/// Time and location rows; a check-out also shows the worked duration and
/// how early the user is leaving.
class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({
    super.key,
    required this.event,
    required this.session,
    required this.earlyLeave,
  });

  final AttendanceEventEntity event;

  /// Today's session (has the check-in time); `null` before check-in.
  final AttendanceSessionEntity? session;
  final Duration earlyLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = event.time;
    final location = event.location;
    final session = this.session;

    final rows = [
      SummaryRow(
        icon: Icons.schedule,
        label: event.type.timeLabel(l10n),
        value: time == null ? '--' : time.formatTime(context),
      ),
      SummaryRow(
        icon: Icons.location_on_outlined,
        label: l10n.location,
        value: location == null
            ? '--'
            : l10n.verifiedAccuracy(location.accuracyMeters.round()),
      ),
      if (event.type == AttendanceType.checkOut && session != null) ...[
        SummaryRow(
          label: l10n.recordedDuration,
          value: time == null
              ? '--'
              : session.workedDuration(time).formatHoursMinutes(context),
        ),
        SummaryRow(
          label: l10n.earlyLeave,
          value: earlyLeave.formatHoursMinutes(context),
          valueColor: earlyLeave > Duration.zero
              ? context.appColors.warning
              : null,
        ),
      ],
    ];

    return CustomContainer(
      horizontalPadding: 16,
      verticalPadding: 5,
      borderWidth: 1,
      borderRadius: 20,
      child: Column(
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index > 0) const Divider(height: 1),
            row,
          ],
        ],
      ),
    );
  }
}
