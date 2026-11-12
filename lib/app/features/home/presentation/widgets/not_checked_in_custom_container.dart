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
import '../../../attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'brand_card.dart';
import 'brand_status_badge.dart';

/// Home card before check-in. Outside the check-in window the button is
/// disabled with the reason (opens later, closed for today); on a day off
/// only the reason is shown.
class NotCheckedInCustomContainer extends StatelessWidget {
  const new({
    super.key,
    required this.shift,
    this.availability = CheckInAvailability.open,
  });

  /// `null` on a day off.
  final ShiftEntity? shift;
  final CheckInAvailability availability;

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
          if (shift != null)
            Opacity(
              opacity: availability == CheckInAvailability.open ? 1 : 0.5,
              child: AppPrimaryButton(
                key: const Key('checkInNow'),
                onPressed: availability == CheckInAvailability.open
                    ? () => context.push(AppRoutes.checkIn)
                    : null,
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
            ),
          if (_reason(context) case final reason?) ...[
            if (shift != null) SizedBox(height: AppSpacing.md),
            Text(
              reason,
              key: const Key('checkInReason'),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: appColors.onBrandSurface,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          if (shift case final shift?) OfficialShiftNote(shift: shift),
        ],
      ),
    );
  }

  String? _reason(BuildContext context) {
    final l10n = context.l10n;
    return switch (availability) {
      CheckInAvailability.open || CheckInAvailability.alreadyCheckedIn => null,
      CheckInAvailability.notWorkingDay => l10n.attendanceNotWorkingDay,
      CheckInAvailability.closed => l10n.attendanceCheckInClosed,
      // The schedule's own wall-clock time (company timezone), not the
      // phone's timezone.
      CheckInAvailability.notYetOpen => l10n.attendanceCheckInOpensAt(
        DateTime(2000).add(shift?.start ?? Duration.zero).formatTime(context),
      ),
    };
  }
}
