import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extensions.dart';

class InActiveStep extends StatelessWidget {
  const InActiveStep({super.key, required this.index, required this.text});
  final int index;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      children: [
        CircleAvatar(
          radius: 12.5,
          backgroundColor: context.colors.outlineVariant,
          child: Text(
            '$index',
            style: context.textTheme.bodySmall!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          text,
          style: context.textTheme.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
