import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/step_item.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:flutter/material.dart';

class AttendanceSteps extends StatelessWidget {
  const AttendanceSteps({
    super.key,
    required this.currentPage,
    required this.onTap,
  });

  final int currentPage;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(getSteps(context).length, (index) {
        return GestureDetector(
          onTap: () {
            onTap(index);
          },
          child: StepItem(
            index: index + 1,
            text: getSteps(context)[index],
            isActive: index <= currentPage,
          ),
        );
      }),
    );
  }

  List<String> getSteps(BuildContext context) {
    return [
      context.l10n.prepare,
      context.l10n.location,
      context.l10n.selfie,
      context.l10n.review,
    ];
  }
}
