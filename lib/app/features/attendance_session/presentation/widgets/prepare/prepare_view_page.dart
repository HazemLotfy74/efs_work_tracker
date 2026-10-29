import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../../../../../core/extensions/date_time_format.dart';
import '../../../../../../core/manager/clock_cubit.dart';
import '../../../../../../core/widgets/app_primary_button.dart';
import '../../../../../../core/widgets/custom_container.dart';
import '../../manager/attendance_flow_cubit/attendance_flow_cubit.dart';
import '../../manager/attendance_session_cubit/attendance_session_cubit.dart';
import '../shift_text.dart';
import '../step_header.dart';
import 'info_row.dart';

class PrepareViewPage extends StatelessWidget {
  const PrepareViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Live: the time updates every minute while the user is on this step.
    final now = context.watch<ClockCubit>().state;
    final attendance = context.watch<AttendanceSessionCubit>().state;
    final shift = attendance is AttendanceSessionLoaded
        ? attendance.shift?.rangeText(context) ?? context.l10n.noShiftToday
        : '--';

    return Column(
      spacing: 20,
      children: [
        StepHeader(
          icon: Icons.work_outline,
          title: context.l10n.readyToStart,
          subtitle: context.l10n.captureLocAndSelfie,
        ),
        CustomContainer(
          horizontalPadding: 20,
          verticalPadding: 20,
          borderWidth: 1,
          child: Column(
            children: [
              InfoRow(
                label: context.l10n.date,
                value: now.formatShortDate(context),
              ),
              const Divider(height: 30),
              InfoRow(
                label: context.l10n.currentTime,
                value: now.formatTime(context),
              ),
              const Divider(height: 30),
              InfoRow(label: context.l10n.shift, value: shift),
            ],
          ),
        ),
        const Spacer(),
        AppPrimaryButton(
          // Stores the time, then opens the Location step.
          onPressed: context.read<AttendanceFlowCubit>().start,
          child: Text(context.l10n.continueTo),
        ),
      ],
    );
  }
}
