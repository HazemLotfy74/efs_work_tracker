import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/theme_context_extensions.dart';

/// Green tile with an icon and a short label, e.g. "Selfie submitted".
class EvidenceConfirmChip extends StatelessWidget {
  const EvidenceConfirmChip({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 62.5,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 5,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(color: colors.primary),
          ),
        ],
      ),
    );
  }
}
