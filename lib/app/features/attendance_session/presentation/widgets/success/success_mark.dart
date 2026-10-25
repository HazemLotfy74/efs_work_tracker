import 'package:flutter/material.dart';

import '../../../../../../core/theme/theme_context_extensions.dart';

/// Big green check in a soft rounded square.
class SuccessMark extends StatelessWidget {
  const SuccessMark({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.12),
            offset: const Offset(0, 14),
            blurRadius: 15,
          ),
        ],
      ),
      child: Icon(Icons.check_rounded, size: 43, color: colors.primary),
    );
  }
}
