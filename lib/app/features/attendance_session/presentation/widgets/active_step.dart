import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

class ActiveStep extends StatelessWidget {
  const ActiveStep({super.key, required this.txt});
  final String txt;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      children: [
        CircleAvatar(
          radius: 12.5,
          backgroundColor: context.colors.primary,
          child: Icon(Icons.check, color: context.colors.surface, size: 15),
        ),
        Text(
          txt,
          style: context.textTheme.bodyMedium!.copyWith(
            color: context.colors.primary,
          ),
        ),
      ],
    );
  }
}
