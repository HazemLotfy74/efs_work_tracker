import 'package:efs_work_tracker/app/features/overtime/presentation/widgets/active_overtime_filter.dart';
import 'package:efs_work_tracker/app/features/overtime/presentation/widgets/inactive_overtime_filter.dart';
import 'package:flutter/material.dart';

class AnimationSelectOvertimeFilter extends StatelessWidget {
  const AnimationSelectOvertimeFilter({
    super.key,
    required this.title,
    required this.isActive,
  });

  final String title;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: ActiveOvertimeFilter(title: title),
      secondChild: InactiveOvertimeFilter(title: title),
      crossFadeState: isActive
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      duration: Duration(milliseconds: 200),
      firstCurve: Curves.easeIn,
      secondCurve: Curves.easeOut,
    );
  }
}
