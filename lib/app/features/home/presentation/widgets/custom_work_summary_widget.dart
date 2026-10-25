import 'package:efs_work_tracker/app/features/home/presentation/widgets/today_over_view_container.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:flutter/material.dart';

class CustomWorkSummaryWidget extends StatelessWidget {
  const CustomWorkSummaryWidget({
    super.key,
    required this.spacing,
    required this.itemWidth,
    this.containerColor,
  });

  final double spacing;
  final double itemWidth;
  final Color? containerColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        TodayOverViewContainer(
          width: itemWidth,
          label: context.l10n.recorded,
          value: '-',
          containerColor: containerColor,
        ),
        TodayOverViewContainer(
          width: itemWidth,
          label: context.l10n.lateness,
          value: '-',
          containerColor: containerColor,
        ),
        TodayOverViewContainer(
          width: itemWidth,
          label: context.l10n.earlyLeave,
          value: '0m',
          containerColor: containerColor,
        ),
        TodayOverViewContainer(
          width: itemWidth,
          label: context.l10n.approvedOT,
          value: '0m',
          containerColor: containerColor,
        ),
      ],
    );
  }
}
