import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/theme_context_extensions.dart';

/// Optional icon, a label and a bold value on the end, 48 high.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData? icon;
  final String label;
  final String value;

  /// Defaults to the normal text color; e.g. warning for early leave.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        spacing: 14,
        children: [
          if (icon != null) Icon(icon, size: 20, color: context.colors.primary),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.itemBody.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.itemTitle.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
