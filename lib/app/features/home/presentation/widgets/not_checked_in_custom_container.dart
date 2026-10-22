import 'package:efs_work_tracker/core/router/app_routes.dart';
import 'package:efs_work_tracker/core/widgets/text_icon_widget.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:efs_work_tracker/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_box_shadow.dart';

class NotCheckedInCustomContainer extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final textTheme = context.textTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        color: appColors.brandSurface,
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                decoration: BoxDecoration(
                  color: appColors.brandSurfaceBadge,
                  borderRadius: BorderRadius.circular(12.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 5,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      decoration: BoxDecoration(
                        color: appColors.onBrandSurface,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      context.l10n.notCheckedIn,
                      style: AppTextStyles.badge.copyWith(
                        color: appColors.onBrandSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            "4:48",
            style: textTheme.displaySmall?.copyWith(
              color: appColors.onBrandSurface,
            ),
          ),
          Text(
            context.l10n.currentLocalTime,
            style: textTheme.bodySmall?.copyWith(
              color: appColors.onBrandSurfaceMuted,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            onPressed: () {
              context.push(AppRoutes.checkIn);
            },
            bgColor: appColors.onBrandSurface,
            child: TextIconWidget(
              txt: context.l10n.checkInNow,
              icon: Icons.camera_alt_outlined,
              style: textTheme.labelLarge!.copyWith(
                color: appColors.brandSurface,
              ),
              iconColor: appColors.brandSurface,
              iconSize: 24,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          TextIconWidget(
            txt: context.l10n.officialShift("8:00", "4:00"),
            icon: Icons.work_history_outlined,
            style: textTheme.bodySmall!.copyWith(
              color: appColors.onBrandSurfaceSubtle,
            ),
            iconColor: appColors.onBrandSurfaceSubtle,
            iconSize: 16,
          ),
        ],
      ),
    );
  }
}
