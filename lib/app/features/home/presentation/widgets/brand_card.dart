import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/utils/app_dimensions.dart';
import '../../../../../core/widgets/custom_box_shadow.dart';
import '../../../../../core/widgets/text_icon_widget.dart';
import '../../../attendance_session/domain/entities/shift_entity.dart';
import '../../../attendance_session/presentation/widgets/shift_text.dart';

/// The dark green card at the top of Home (not checked in, active session,
/// checked out all use it).
class BrandCard extends StatelessWidget {
  const BrandCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.appColors.brandSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          customBoxShadow(
            blur: 32,
            x: 0,
            y: 18,
            color: context.colors.shadow.withAlpha(10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// "Official shift · 8:00 AM – 4:00 PM" at the bottom of [BrandCard].
class OfficialShiftNote extends StatelessWidget {
  const OfficialShiftNote({super.key, required this.shift});

  final ShiftEntity shift;

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.onBrandSurfaceSubtle;
    return TextIconWidget(
      txt: context.l10n.officialShift(
        shift.startText(context),
        shift.endText(context),
      ),
      icon: Icons.work_history_outlined,
      style: context.textTheme.bodySmall!.copyWith(color: color),
      iconColor: color,
      iconSize: 16,
    );
  }
}
