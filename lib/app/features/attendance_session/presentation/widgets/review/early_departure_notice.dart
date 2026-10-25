import 'package:flutter/material.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../../../../../core/extensions/duration_format.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/theme_context_extensions.dart';

/// Yellow warning shown on Review when checking out before the shift ends.
class EarlyDepartureNotice extends StatelessWidget {
  const EarlyDepartureNotice({super.key, required this.earlyLeave});

  final Duration earlyLeave;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.warningContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: appColors.warning),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  context.l10n.earlyDeparture,
                  style: AppTextStyles.itemTitle.copyWith(
                    color: appColors.warning,
                  ),
                ),
                Text(
                  context.l10n.earlyDepartureMessage(
                    earlyLeave.formatHoursMinutes(context),
                  ),
                  style: AppTextStyles.meta.copyWith(color: appColors.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
