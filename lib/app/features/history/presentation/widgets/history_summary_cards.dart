import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/duration_format.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../domain/attendance_history_summary.dart';

class HistorySummaryCards extends StatelessWidget {
  const HistorySummaryCards({super.key, required this.summary});
  final AttendanceHistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (
        l10n.historyRecordedWork,
        summary.worked.formatHoursMinutes(context),
        l10n.historyAttendanceDays(summary.days),
      ),
      (
        l10n.historyLateArrivals,
        '${summary.lateDays}',
        l10n.historyMinutesTotal(summary.lateMinutes),
      ),
      (
        l10n.observedOvertime,
        summary.overtime.formatHoursMinutes(context),
        l10n.historyOvertimeDays(summary.overtimeDays),
      ),
    ];
    Widget card(int index) {
      final featured = index == 0;
      final foreground = featured
          ? context.appColors.onBrandSurface
          : context.appColors.headingText;
      final muted = featured
          ? context.appColors.onBrandSurfaceMuted
          : context.colors.onSurfaceVariant;
      return CustomContainer(
        borderWidth: featured ? 0 : 1,
        borderRadius: 18,
        horizontalPadding: 14,
        verticalPadding: 12,
        containerColor: featured
            ? context.appColors.brandSurface
            : context.colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              items[index].$1,
              style: context.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 6),
            Text(
              items[index].$2,
              style: context.textTheme.titleLarge?.copyWith(color: foreground),
            ),
            const SizedBox(height: 6),
            Text(
              items[index].$3,
              style: context.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        if (constraints.maxWidth / scale < 350) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                card(i),
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(flex: i == 0 ? 5 : 4, child: card(i)),
              ],
            ],
          ),
        );
      },
    );
  }
}
