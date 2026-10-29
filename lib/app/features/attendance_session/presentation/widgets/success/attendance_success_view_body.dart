import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../../../../../core/extensions/date_time_format.dart';
import '../../../../../../core/extensions/duration_format.dart';
import '../../../../../../core/router/app_routes.dart';
import '../../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../../core/widgets/app_primary_button.dart';
import '../../../../home/presentation/widgets/custom_status_container.dart';
import '../../../domain/entities/attendance_type.dart';
import '../../manager/attendance_session_cubit/attendance_session_cubit.dart';
import '../attendance_type_text.dart';
import 'evidence_confirm_chip.dart';
import 'success_mark.dart';
import 'success_summary_card.dart';

class AttendanceSuccessViewBody extends StatelessWidget {
  const AttendanceSuccessViewBody({super.key, required this.type});

  final AttendanceType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attendance = context.watch<AttendanceSessionCubit>().state;
    // The session just saved by the Review step.
    final session = attendance is AttendanceSessionLoaded
        ? attendance.session
        : null;
    final now = DateTime.now();

    final (subtitle, cardLabel, cardValue, cardDate) = switch (type) {
      AttendanceType.checkIn => (
        l10n.yourSessionIsNowActive,
        l10n.confirmedAt,
        (session?.checkInTime ?? now).formatTime(context),
        session?.checkInTime ?? now,
      ),
      AttendanceType.checkOut => (
        session != null && session.earlyLeave > Duration.zero
            ? l10n.checkoutRecordedEarly
            : l10n.checkoutRecorded,
        l10n.finalDuration,
        session?.verifiedDuration?.worked.formatHoursMinutes(context) ?? '--',
        session?.checkOutTime ?? now,
      ),
    };

    return Column(
      children: [
        const SizedBox(height: 40),
        const SuccessMark(),
        const SizedBox(height: 18),
        CustomStatusContainer(
          tone: StatusTone.success,
          text: type.doneLabel(l10n),
        ),
        const SizedBox(height: 12),
        Text(
          type.successTitle(l10n),
          textAlign: TextAlign.center,
          style: context.textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        SuccessSummaryCard(
          label: cardLabel,
          value: cardValue,
          date: cardDate.formatLongDate(context),
        ),
        const SizedBox(height: 14),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: EvidenceConfirmChip(
                icon: Icons.camera_alt_outlined,
                text: l10n.selfieSubmitted,
              ),
            ),
            Expanded(
              child: EvidenceConfirmChip(
                icon: Icons.location_on_outlined,
                text: l10n.locationVerified,
              ),
            ),
          ],
        ),
        const Spacer(),
        switch (type) {
          AttendanceType.checkIn => AppPrimaryButton(
            // go (not pop): home becomes the only screen, so back can't
            // return to this screen.
            onPressed: () => context.go(AppRoutes.home),
            child: Text(l10n.returnToHome),
          ),
          AttendanceType.checkOut => AppPrimaryButton(
            // Replace this screen, so back from details goes home.
            onPressed: () => context.pushReplacement(
              AppRoutes.attendanceDetailsOf(session?.id ?? ''),
            ),
            child: Text(l10n.viewAttendanceDetails),
          ),
        },
      ],
    );
  }
}
