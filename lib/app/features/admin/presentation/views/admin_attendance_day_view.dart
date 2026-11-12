import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/extensions/duration_format.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../attendance_correction/domain/correction_rules.dart';
import '../../../attendance_correction/presentation/widgets/correction_request_details.dart';
import '../../../attendance_correction/presentation/widgets/correction_text.dart';
import '../../../attendance_session/presentation/widgets/attendance_day_status_text.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../../auth/presentation/manager/auth_cubit/auth_cubit.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';
import '../../domain/repositories/admin_repository.dart';
import '../manager/attendance_day_cubit/attendance_day_cubit.dart';
import '../widgets/attendance_evidence_card.dart';
import '../widgets/attendance_flag_chips.dart';
import '../../../permissions/domain/entities/permission_set.dart';
import '../../../permissions/presentation/permissions_context.dart';

/// Admin only: one attendance day with its times, flags, correction
/// requests and the check-in / check-out evidence.
class AdminAttendanceDayView extends StatelessWidget {
  const AdminAttendanceDayView({
    super.key,
    required this.attendanceId,
    this.showMaps = true,
    this.showEditAction = Constants.adminAttendanceCorrection,
  });

  final String attendanceId;

  /// Off in tests (map tiles come from the network).
  final bool showMaps;

  /// Offer "Edit times" (needs `admin_correct_attendance` in the database).
  final bool showEditAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) =>
          AttendanceDayCubit(context.read<AdminRepository>(), attendanceId)
            ..load(),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            spacing: 16,
            children: [
              customAppBar(
                context: context,
                title: l10n.adminAttendanceDay,
                leading: CustomBackButton(),
              ),
              Expanded(
                child: BlocBuilder<AttendanceDayCubit, AttendanceDayState>(
                  builder: (context, state) => switch (state) {
                    AttendanceDayLoading() => AppLoadingView(
                      title: l10n.adminAttendanceDay,
                      message: '',
                    ),
                    AttendanceDayError() => AppErrorView(
                      title: l10n.attendanceLoadFailed,
                      message: l10n.authNetworkError,
                      onRetry: context.read<AttendanceDayCubit>().load,
                    ),
                    AttendanceDayNotFound() => AppEmptyView(
                      title: l10n.attendanceNotFound,
                      message: '',
                      actionLabel: null,
                    ),
                    AttendanceDayLoaded() => _Day(
                      state: state,
                      showMaps: showMaps,
                      showEditAction: showEditAction,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.state,
    required this.showMaps,
    required this.showEditAction,
  });

  final AttendanceDayLoaded state;
  final bool showMaps;
  final bool showEditAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = context.watch<ClockCubit>().state;
    final cubit = context.read<AttendanceDayCubit>();
    final session = state.day.session;
    final timezone = session.timezone;
    String time(DateTime instant) =>
        CorrectionRules.wallClock(timezone, instant).formatTime(context);
    final date = session.workDate ?? session.checkInTime;
    final status = session.statusAt(now);
    final duration = session.durationAt(now);
    final effectiveIn = session.effectiveCheckIn;
    final effectiveOut = session.effectiveCheckOut;
    final me = context.select<AuthCubit, String?>(
      (auth) => switch (auth.state) {
        AuthSignedIn(:final user) => user.uID,
        _ => null,
      },
    );
    // admin_correct_attendance: closed days of other employees only. It is
    // the database that enforces this and the attendance.edit permission.
    final canEdit =
        showEditAction &&
        context.permissions.can(Permission.attendanceEdit) &&
        state.day.employeeId != me &&
        (session.checkOut != null || session.isAutoClosed);

    return ListView(
      children: [
        CustomContainer(
          borderWidth: 1,
          horizontalPadding: 16,
          verticalPadding: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                state.employee?.fullName ?? '',
                style: context.textTheme.titleMedium,
              ),
              Text(
                date.formatFullDate(context),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  CustomStatusContainer(
                    tone: status.tone,
                    text: status.label(l10n),
                  ),
                ],
              ),
              AttendanceFlagChips(day: session, now: now),
              const Divider(),
              InfoRow(
                label: l10n.adminScheduledShift,
                value:
                    '${time(session.shift.startsAt ?? session.checkInTime)}'
                    ' – ${time(session.scheduledEnd)}',
              ),
              InfoRow(label: l10n.checkedIn, value: time(session.checkInTime)),
              InfoRow(
                label: l10n.checkedOut,
                value: switch (session.checkOutTime) {
                  final out? => time(out),
                  null => '--',
                },
              ),
              InfoRow(
                label: l10n.adminWorked,
                value:
                    duration?.worked.formatHoursMinutes(context) ??
                    l10n.notConfirmed,
              ),
              InfoRow(
                label: l10n.observedOvertime,
                value: duration?.overtime.formatHoursMinutes(context) ?? '--',
              ),
              InfoRow(
                label: l10n.adminLateBy,
                value: Duration(minutes: session.lateMinutes)
                    .formatHoursMinutes(context),
              ),
              InfoRow(
                label: l10n.adminEarlyBy,
                value: session.leftEarlyBy.formatHoursMinutes(context),
              ),
              if (session.hasCorrection && effectiveIn != null)
                InfoRow(
                  label: l10n.adminEffectiveTimes,
                  value:
                      '${time(effectiveIn)} – '
                      '${effectiveOut == null ? '--' : time(effectiveOut)}',
                ),
              if (timezone != null)
                Text(
                  l10n.correctionTimezoneNote(timezone),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (canEdit) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('editTimes'),
            onPressed: () async {
              final saved = await context.push<bool>(
                AppRoutes.adminEditAttendanceOf(session.id),
              );
              if (saved == true) await cubit.load();
            },
            icon: const Icon(Icons.edit_calendar_outlined),
            label: Text(l10n.adminEditTimes),
          ),
        ],
        const SizedBox(height: 12),
        CustomContainer(
          borderWidth: 1,
          horizontalPadding: 16,
          verticalPadding: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(l10n.adminCorrections, style: context.textTheme.titleMedium),
              if (state.corrections.isEmpty)
                Text(
                  l10n.adminNoCorrections,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              for (final request in state.corrections) ...[
                CustomStatusContainer(
                  tone: request.status.tone,
                  text: request.status.label(l10n),
                ),
                CorrectionRequestDetails(request: request, timezone: timezone),
                const Divider(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        AttendanceEvidenceCard(
          key: const Key('checkInEvidence'),
          title: l10n.adminCheckInEvidence,
          event: session.checkIn,
          timezone: timezone,
          photoUrl: cubit.evidenceUrl,
          showMap: showMaps,
        ),
        const SizedBox(height: 12),
        AttendanceEvidenceCard(
          key: const Key('checkOutEvidence'),
          title: l10n.adminCheckOutEvidence,
          event: session.checkOut,
          timezone: timezone,
          photoUrl: cubit.evidenceUrl,
          showMap: showMaps,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
