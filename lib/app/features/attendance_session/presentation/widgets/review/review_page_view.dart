import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../../../../../core/router/app_routes.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../../core/widgets/app_primary_button.dart';
import '../../../domain/entities/attendance_type.dart';
import '../../manager/attendance_flow_cubit/attendance_flow_cubit.dart';
import '../../manager/attendance_session_cubit/attendance_session_cubit.dart';
import '../attendance_type_text.dart';
import 'early_departure_notice.dart';
import 'review_evidence_card.dart';
import 'review_summary_card.dart';

/// Last step: shows everything captured before confirming, then saves it.
class ReviewPageView extends StatefulWidget {
  const ReviewPageView({super.key});

  @override
  State<ReviewPageView> createState() => _ReviewPageViewState();
}

class _ReviewPageViewState extends State<ReviewPageView> {
  bool _isSaving = false;

  Future<void> _confirm() async {
    final event = context.read<AttendanceFlowCubit>().event;
    setState(() => _isSaving = true);
    try {
      await context.read<AttendanceSessionCubit>().record(event);
      if (!mounted) return;
      // Replace the flow, so back from the success screen goes home.
      context.pushReplacement(switch (event.type) {
        AttendanceType.checkIn => AppRoutes.checkInSuccess,
        AttendanceType.checkOut => AppRoutes.checkOutSuccess,
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.saveAttendanceFailed)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = context.watch<AttendanceFlowCubit>().state.event;
    final attendance = context.watch<AttendanceSessionCubit>().state;
    // Today's session, needed for the check-out rows (duration, early leave).
    final session = attendance is AttendanceSessionLoaded
        ? attendance.session
        : null;
    final time = event.time;
    final earlyLeave =
        event.type == AttendanceType.checkOut && session != null && time != null
        ? session.shift.earlyLeaveFor(time)
        : Duration.zero;

    return Column(
      spacing: 18,
      children: [
        // Scrolls on small phones (check-out has more rows); the button
        // stays at the bottom.
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              spacing: 18,
              children: [
                Text(
                  context.l10n.reviewAndConfirm,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineMedium,
                ),
                Text(
                  context.l10n.makeSure,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.lead.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                ReviewEvidenceCard(event: event),
                ReviewSummaryCard(
                  event: event,
                  session: session,
                  earlyLeave: earlyLeave,
                ),
                if (earlyLeave > Duration.zero)
                  EarlyDepartureNotice(earlyLeave: earlyLeave),
              ],
            ),
          ),
        ),
        AppPrimaryButton(
          onPressed: event.isComplete && !_isSaving ? _confirm : null,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: [
                    const Icon(Icons.check, size: 20),
                    Text(event.type.confirmLabel(context.l10n)),
                  ],
                ),
        ),
      ],
    );
  }
}
