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

/// Home card before check-in. Without [canCheckIn] (a day off, or the shift
/// is over) it explains why instead of showing the button.
class NotCheckedInCustomContainer extends StatelessWidget {
  const new({super.key, required this.shift, this.canCheckIn = true});

  /// `null` on a day off.
  final ShiftEntity? shift;
  final bool canCheckIn;

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
          if (canCheckIn)
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
            )
          else
            Text(
              shift == null
                  ? context.l10n.attendanceNotWorkingDay
                  : context.l10n.attendanceCheckInClosed,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: appColors.onBrandSurface,
              ),
            ),
          SizedBox(height: AppSpacing.lg),
          if (shift case final shift?) OfficialShiftNote(shift: shift),
        ],
      ),
    );
  }
}
