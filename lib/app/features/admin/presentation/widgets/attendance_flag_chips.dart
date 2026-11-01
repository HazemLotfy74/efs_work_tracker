import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';
import '../../domain/entities/employee_attendance_stats.dart';

extension AttendanceFlagText on AttendanceFlag {
  String label(AppLocalizations l10n, AttendanceSessionEntity day) =>
      switch (this) {
        AttendanceFlag.late => l10n.lateMinutes(day.lateMinutes),
        AttendanceFlag.leftEarly => l10n.adminLeftEarly,
        AttendanceFlag.missingCheckOut => l10n.adminStatMissing,
        AttendanceFlag.corrected => l10n.adminFlagCorrected,
      };

  StatusTone get tone => switch (this) {
    AttendanceFlag.corrected => StatusTone.success,
    AttendanceFlag.missingCheckOut => StatusTone.error,
    _ => StatusTone.warning,
  };
}

/// The day's flags as badges; nothing when there are none.
class AttendanceFlagChips extends StatelessWidget {
  const AttendanceFlagChips({super.key, required this.day, required this.now});

  final AttendanceSessionEntity day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final flags = AttendanceFlag.of(day, now);
    if (flags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final flag in flags)
          CustomStatusContainer(tone: flag.tone, text: flag.label(l10n, day)),
      ],
    );
  }
}
