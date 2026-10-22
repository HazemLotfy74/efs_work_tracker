import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/active_step.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/in_active_step.dart';
import 'package:flutter/material.dart';

class StepItem extends StatelessWidget {
  const StepItem({
    super.key,
    required this.index,
    required this.text,
    required this.isActive,
  });

  final int index;
  final String text;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: InActiveStep(index: index, text: text),
      secondChild: ActiveStep(txt: text),
      crossFadeState: isActive
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: Duration(milliseconds: 300),
    );
  }
}
