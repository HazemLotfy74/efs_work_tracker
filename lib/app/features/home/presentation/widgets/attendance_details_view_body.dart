import 'package:efs_work_tracker/app/features/home/presentation/widgets/attendance_event_widget.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/attendance_status_details_container.dart';
import 'package:efs_work_tracker/core/widgets/custom_back_button.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/no_chekout_record_warning_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/duration_format.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../attendance_correction/presentation/widgets/correction_section.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../manager/attendance_details_cubit/attendance_details_cubit.dart';
import 'custom_work_summary_widget.dart';

class AttendanceDetailsViewBody extends StatelessWidget {
  const AttendanceDetailsViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      spacing: 20,
      children: [
        customAppBar(
          context: context,
          title: l10n.attendanceDetails,
          leading: CustomBackButton(),
        ),
        Expanded(
          child: BlocBuilder<AttendanceDetailsCubit, AttendanceDetailsState>(
            builder: (context, state) => switch (state) {
              AttendanceDetailsLoading() => AppLoadingView(
                title: l10n.attendanceDetails,
                message: '',
              ),
              AttendanceDetailsError() => AppErrorView(
                title: l10n.attendanceLoadFailed,
                message: l10n.authNetworkError,
                onRetry: context.read<AttendanceDetailsCubit>().load,
              ),
              AttendanceDetailsNotFound() => AppEmptyView(
                title: l10n.attendanceNotFound,
                message: '',
                actionLabel: null,
              ),
              AttendanceDetailsLoaded(:final session) => _Details(
                session: session,
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.session});

  final AttendanceSessionEntity session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = context.watch<ClockCubit>().state;
    final status = session.statusAt(now);
    final overtime = session.durationAt(now)?.overtime ?? Duration.zero;

    return SingleChildScrollView(
      child: Column(
        spacing: 20,
        children: [
          AttendanceStatusDetailsContainer(session: session, status: status),
          if (status == AttendanceDayStatus.needsReview)
            NoChekoutRecordWarningWidget(),
          if (session.needsReview || session.hasCorrection)
            CorrectionSection(session: session),
          CustomContainer(
            borderWidth: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(l10n.workSummary, style: context.textTheme.titleMedium),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = 10.0;
                    final itemWidth = (constraints.maxWidth - spacing) / 2;
                    return CustomWorkSummaryWidget(
                      spacing: spacing,
                      itemWidth: itemWidth,
                      containerColor: context.colors.surfaceContainerLow,
                      session: session,
                      now: now,
                    );
                  },
                ),
                if (overtime > Duration.zero)
                  Text(
                    '${l10n.observedOvertime}: '
                    '${overtime.formatHoursMinutes(context)}. '
                    '${l10n.observedOvertimeNote}',
                    style: AppTextStyles.meta.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          AttendanceEventWidget(session: session, status: status),
        ],
      ),
    );
  }
}
