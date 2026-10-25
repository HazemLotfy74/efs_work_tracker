import 'package:flutter/material.dart';

import '../../../../../../core/theme/theme_context_extensions.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelLarge;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 12,
      children: [
        Text(
          label,
          style: style?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        // Wraps instead of overflowing with long values or large text.
        Flexible(
          child: Text(value, textAlign: TextAlign.end, style: style),
        ),
      ],
    );
  }
}
