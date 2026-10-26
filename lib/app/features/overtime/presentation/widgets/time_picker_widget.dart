
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const TimePickerField({
    super.key,
    required this.label,
    required this.selectedTime,
    required this.onTimeChanged,
  });

  Future<void> _selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: 'Select $label',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: context.colors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      onTimeChanged(pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF40566A),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: const Color(0xFFF7FAF9),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _selectTime(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 17,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFDCE8E3),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                selectedTime.format(context),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF193A37),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
