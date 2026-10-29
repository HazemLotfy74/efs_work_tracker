import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/extensions/duration_format.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/utils/app_dimensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/elapsed_time_text.dart';
import '../../../attendance_session/domain/entities/work_duration.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import 'brand_card.dart';
import 'brand_status_badge.dart';

/// Home card once the user checked in today.
/// - Active: live timer, check-in time, shift end and "Check out".
/// - Closed automatically (no check-out by the shift end): regular time,
///   the closing time and a pointer to overtime requests. The database
///   records no check-out after the shift end, so none is offered.
/// - Finished: total time, check-in and check-out times, and details.
class AttendanceSessionCard extends StatelessWidget {
  const AttendanceSessionCard({
    super.key,
    required this.session,
    required this.now,
  });

  final AttendanceSessionEntity session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appColors = context.appColors;
    final textTheme = context.textTheme;
    final active = session.isActiveAt(now);
    // Also before the server's close has run: it closes at the shift end.
    final closedAutomatically = !active && session.checkOut == null;
    final checkOutTime = session.checkOutTime;
    // Verified time once ended; `null` when the hours aren't confirmed.
    final verified = session.verifiedDuration;
    final bigStyle = textTheme.displaySmall?.copyWith(
      color: appColors.onBrandSurface,
    );
    final noteStyle = textTheme.bodySmall?.copyWith(
      color: appColors.onBrandSurfaceMuted,
    );
    final lineColor = appColors.onBrandSurface.withValues(alpha: 0.1);

    return BrandCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BrandStatusBadge(
                text: active
                    ? l10n.checkedIn
                    : closedAutomatically
                    ? l10n.closedAutomatically
                    : l10n.checkedOut,
              ),
              if (active) const _LiveLabel(),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (active)
            ElapsedTimeText(since: session.checkInTime, style: bigStyle)
          else
            Text(
              verified?.worked.formatHoursMinutes(context) ?? l10n.notConfirmed,
              style: bigStyle,
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            active
                ? l10n.elapsedWorkingTime
                : verified == null
                ? l10n.needsReview
                : l10n.totalWorkingTime,
            style: textTheme.bodySmall?.copyWith(
              color: appColors.onBrandSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Divider(height: 1, color: lineColor),
          const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _TimeColumn(
                    label: l10n.checkedIn,
                    value: session.checkInTime.formatTime(context),
                  ),
                ),
                VerticalDivider(width: 1, color: lineColor),
                Expanded(
                  child: switch (checkOutTime) {
                    final out? => _TimeColumn(
                      label: l10n.checkedOut,
                      value: out.formatTime(context),
                    ),
                    null when closedAutomatically => _TimeColumn(
                      label: l10n.closedAt,
                      value: (session.autoClosedAt ?? session.closeDeadline)
                          .formatTime(context),
                    ),
                    null => _TimeColumn(
                      label: l10n.regularHoursEnd,
                      value: session.checkInTime
                          .add(WorkDuration.regularLimit)
                          .formatTime(context),
                    ),
                  },
                ),
              ],
            ),
          ),
          if (closedAutomatically) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.autoClosedNote(
                (session.autoClosedAt ?? session.closeDeadline).formatTime(
                  context,
                ),
              ),
              textAlign: TextAlign.center,
              style: noteStyle,
            ),
          ] else if (active && session.endsBeforeRegularHours) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.closesBeforeRegularHours(
                session.closeDeadline.formatTime(context),
              ),
              textAlign: TextAlign.center,
              style: noteStyle,
            ),
          ] else if (verified != null && verified.overtime > Duration.zero) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${l10n.observedOvertime}: '
              '${verified.overtime.formatHoursMinutes(context)}. '
              '${l10n.observedOvertimeNote}',
              textAlign: TextAlign.center,
              style: noteStyle,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            bgColor: appColors.onBrandSurface,
            onPressed: () => context.push(
              active
                  ? AppRoutes.checkOut
                  : AppRoutes.attendanceDetailsOf(session.id),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                Icon(
                  active ? Icons.logout : Icons.receipt_long_outlined,
                  size: 20,
                  color: appColors.brandSurface,
                ),
                // Flexible: a long label shrinks instead of overflowing.
                Flexible(
                  child: Text(
                    active ? l10n.checkOutPage : l10n.viewAttendanceDetails,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge!.copyWith(
                      color: appColors.brandSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OfficialShiftNote(shift: session.shift),
        ],
      ),
    );
  }
}

/// Green dot + "LIVE" while the session is running.
class _LiveLabel extends StatelessWidget {
  const _LiveLabel();

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: appColors.onBrandSurface,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          context.l10n.live,
          style: AppTextStyles.micro.copyWith(
            color: appColors.onBrandSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

/// Small label over a bold time, centered.
class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Column(
      spacing: 3,
      children: [
        Text(
          label,
          style: AppTextStyles.meta.copyWith(
            color: appColors.onBrandSurfaceMuted,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: appColors.onBrandSurface,
          ),
        ),
      ],
    );
  }
}
