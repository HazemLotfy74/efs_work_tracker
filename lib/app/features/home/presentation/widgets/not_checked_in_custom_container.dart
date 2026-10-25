import 'package:efs_work_tracker/core/router/app_routes.dart';
import 'package:efs_work_tracker/core/widgets/text_icon_widget.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:efs_work_tracker/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../attendance_session/domain/entities/shift_entity.dart';
import 'brand_card.dart';
import 'brand_status_badge.dart';

class NotCheckedInCustomContainer extends StatelessWidget {
  const new({super.key, required this.shift});

  final ShiftEntity shift;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final textTheme = context.textTheme;
    return BrandCard(
      child: Column(
        children: [
          Row(children: [BrandStatusBadge(text: context.l10n.notCheckedIn)]),
          SizedBox(height: AppSpacing.lg),
          BlocBuilder<ClockCubit, DateTime>(
            builder: (context, now) => Text(
              now.formatClock(context),
              style: textTheme.displaySmall?.copyWith(
                color: appColors.onBrandSurface,
              ),
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
          OfficialShiftNote(shift: shift),
        ],
      ),
    );
  }
}
