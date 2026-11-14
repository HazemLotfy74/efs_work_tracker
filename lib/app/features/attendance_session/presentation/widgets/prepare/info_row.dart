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
        // Both sides wrap within their share (label up to 2/5, value up to
        // 3/5) instead of overflowing: a long Arabic label on a narrow
        // phone with large text used to push the value off the screen.
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: style?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        Flexible(
          flex: 3,
          child: Text(value, textAlign: TextAlign.end, style: style),
        ),
      ],
    );
  }
}
