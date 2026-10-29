import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import 'attendance_session_card.dart';
import 'brand_card.dart';
import 'not_checked_in_custom_container.dart';

/// Picks the Home attendance card from today's session.
class TodayAttendanceCard extends StatelessWidget {
  const TodayAttendanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    // Re-evaluated every minute, so the card changes when the shift ends.
    final now = context.watch<ClockCubit>().state;
    return BlocBuilder<AttendanceSessionCubit, AttendanceSessionState>(
      builder: (context, state) => switch (state) {
        AttendanceSessionLoading() => BrandCard(
          child: SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: appColors.onBrandSurface),
            ),
          ),
        ),
        AttendanceSessionError() => BrandCard(
          child: Column(
            spacing: 12,
            children: [
              Text(
                context.l10n.attendanceLoadFailed,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: appColors.onBrandSurface,
                ),
              ),
              TextButton(
                onPressed: context.read<AttendanceSessionCubit>().load,
                child: Text(
                  context.l10n.tryAgain,
                  style: TextStyle(color: appColors.onBrandSurface),
                ),
              ),
            ],
          ),
        ),
        AttendanceSessionLoaded(:final session?) => AttendanceSessionCard(
          session: session,
          now: now,
        ),
        AttendanceSessionLoaded(:final shift) => NotCheckedInCustomContainer(
          shift: shift,
          canCheckIn: state.canCheckInAt(now),
        ),
      },
    );
  }
}
