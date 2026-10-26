
import 'package:efs_work_tracker/app/features/overtime/presentation/widgets/time_picker_widget.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:flutter/material.dart';

class OvertimeTimeSection extends StatefulWidget {
  const OvertimeTimeSection({super.key});

  @override
  State<OvertimeTimeSection> createState() =>
      _OvertimeTimeSectionState();
}

class _OvertimeTimeSectionState
    extends State<OvertimeTimeSection> {
  TimeOfDay startTime = const TimeOfDay(
    hour: 16,
    minute: 0,
  );

  TimeOfDay endTime = const TimeOfDay(
    hour: 18,
    minute: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TimePickerField(
            label: context.l10n.startTime,
            selectedTime: startTime,
            onTimeChanged: (time) {
              setState(() => startTime = time);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TimePickerField(
            label: context.l10n.endTome,
            selectedTime: endTime,
            onTimeChanged: (time) {
              setState(() => endTime = time);
            },
          ),
        ),
      ],
    );
  }
}
