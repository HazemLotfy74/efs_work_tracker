import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/extensions/duration_format.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/feedback/app_dialog.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../../core/widgets/pickers/app_pickers.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../attendance_correction/domain/correction_rules.dart';
import '../../../attendance_session/domain/entities/work_duration.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../domain/repositories/admin_repository.dart';
import '../manager/edit_attendance_cubit/edit_attendance_cubit.dart';
import '../widgets/admin_failure_text.dart';

/// Admin only: correct the check-in / check-out of one closed day. Pops
/// `true` once saved.
class EditAttendanceView extends StatelessWidget {
  const EditAttendanceView({super.key, required this.attendanceId});

  final String attendanceId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) =>
          EditAttendanceCubit(context.read<AdminRepository>(), attendanceId)
            ..load(),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            spacing: 16,
            children: [
              customAppBar(
                context: context,
                title: l10n.adminEditTimes,
                leading: CustomBackButton(),
              ),
              Expanded(
                child: BlocConsumer<EditAttendanceCubit, EditAttendanceState>(
                  listener: (context, state) {
                    if (state is EditAttendanceSaved) {
                      showAppSnackBar(
                        ScaffoldMessenger.of(context),
                        l10n.adminTimesSaved,
                        type: AppMessageType.success,
                      );
                      context.pop(true);
                    }
                  },
                  buildWhen: (previous, current) =>
                      current is! EditAttendanceSaved,
                  builder: (context, state) => switch (state) {
                    EditAttendanceLoading() || EditAttendanceSaved() =>
                      AppLoadingView(title: l10n.adminEditTimes, message: ''),
                    EditAttendanceError() => AppErrorView(
                      title: l10n.attendanceLoadFailed,
                      message: l10n.authNetworkError,
                      onRetry: context.read<EditAttendanceCubit>().load,
                    ),
                    EditAttendanceNotFound() => AppEmptyView(
                      title: l10n.attendanceNotFound,
                      message: '',
                      actionLabel: null,
                    ),
                    EditAttendanceReady() => _Form(state: state),
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

class _Form extends StatefulWidget {
  const _Form({required this.state});

  final EditAttendanceReady state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _reason = TextEditingController();

  /// Times of day on the work date, in the day's timezone. They start at
  /// the times that count today: corrected ones, else the recorded ones.
  late Duration? _checkIn = _timeOf(
    widget.state.day.session.effectiveCheckIn ??
        widget.state.day.session.checkInTime,
  );
  late Duration? _checkOut =
      switch (widget.state.day.session.effectiveCheckOut ??
      widget.state.day.session.checkOutTime) {
        final out? => _timeOf(out),
        null => null,
      };

  Duration _timeOf(DateTime instant) =>
      CorrectionRules.timeOfDay(widget.state.day.session.timezone, instant);

  DateTime? _at(Duration? time) => time == null
      ? null
      : CorrectionRules.onWorkDate(widget.state.day.session, time);

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool checkIn}) async {
    final l10n = context.l10n;
    final current =
        (checkIn ? _checkIn : _checkOut) ??
        _timeOf(widget.state.day.session.scheduledEnd);
    final picked = await showAppTimePicker(
      context,
      initialTime: TimeOfDay(
        hour: current.inHours,
        minute: current.inMinutes.remainder(60),
      ),
      helpText: checkIn ? l10n.correctionCheckIn : l10n.correctionCheckOut,
    );
    if (picked == null || !mounted) return;
    final time = Duration(hours: picked.hour, minutes: picked.minute);
    setState(() => checkIn ? _checkIn = time : _checkOut = time);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    final cubit = context.read<EditAttendanceCubit>();
    final checkIn = _at(_checkIn);
    final checkOut = _at(_checkOut);
    // Show form problems at once; ask to confirm only valid corrections.
    if (cubit.check(
          checkIn: checkIn,
          checkOut: checkOut,
          reason: _reason.text,
        ) !=
        null) {
      await cubit.save(
        checkIn: checkIn,
        checkOut: checkOut,
        reason: _reason.text,
      );
      return;
    }
    final session = widget.state.day.session;
    String time(DateTime? instant) => instant == null
        ? '--'
        : CorrectionRules.wallClock(
            session.timezone,
            instant,
          ).formatTime(context);
    final worked = WorkDuration(checkOut!.difference(checkIn!));
    final confirmed = await showAppConfirmationDialog(
      context,
      title: l10n.adminConfirmEditTitle,
      message: [
        '${l10n.correctionCheckIn}: ${time(session.checkInTime)} → ${time(checkIn)}',
        '${l10n.correctionCheckOut}: ${time(session.checkOutTime)} → ${time(checkOut)}',
        '${l10n.adminWorked}: ${worked.worked.formatHoursMinutes(context)}',
        '${l10n.observedOvertime}: ${worked.overtime.formatHoursMinutes(context)}',
      ].join('\n'),
      confirmLabel: l10n.adminSaveTimes,
      cancelLabel: l10n.correctionCancel,
    );
    if (!confirmed) return;
    await cubit.save(
      checkIn: checkIn,
      checkOut: checkOut,
      reason: _reason.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final session = state.day.session;
    final timezone = session.timezone;
    String time(DateTime? instant) => instant == null
        ? '--'
        : CorrectionRules.wallClock(timezone, instant).formatTime(context);
    String clock(Duration? value) => value == null
        ? l10n.correctionPickTime
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(
              hour: value.inHours,
              minute: value.inMinutes.remainder(60),
            ),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          );
    final preview = switch ((_at(_checkIn), _at(_checkOut))) {
      (final checkIn?, final checkOut?) when !checkOut.isBefore(checkIn) =>
        WorkDuration(checkOut.difference(checkIn)),
      _ => null,
    };
    final saving = state.saving;
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
                (session.workDate ?? session.checkInTime).formatFullDate(
                  context,
                ),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const Divider(),
              Text(
                l10n.adminRecordedTimes,
                style: context.textTheme.labelLarge,
              ),
              InfoRow(
                label: l10n.correctionCheckIn,
                value: time(session.checkInTime),
              ),
              InfoRow(
                label: l10n.correctionCheckOut,
                value: time(session.checkOutTime),
              ),
              if (session.hasCorrection) ...[
                Text(
                  l10n.adminEffectiveTimes,
                  style: context.textTheme.labelLarge,
                ),
                InfoRow(
                  label: l10n.correctionCheckIn,
                  value: time(session.effectiveCheckIn),
                ),
                InfoRow(
                  label: l10n.correctionCheckOut,
                  value: time(session.effectiveCheckOut),
                ),
              ],
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
        const SizedBox(height: 16),
        _TimeTile(
          key: const Key('editCheckIn'),
          label: l10n.correctionCheckIn,
          value: clock(_checkIn),
          onTap: saving ? null : () => _pick(checkIn: true),
        ),
        const SizedBox(height: 10),
        _TimeTile(
          key: const Key('editCheckOut'),
          label: l10n.correctionCheckOut,
          value: clock(_checkOut),
          onTap: saving ? null : () => _pick(checkIn: false),
        ),
        if (preview != null) ...[
          const SizedBox(height: 10),
          InfoRow(
            label: l10n.adminWorked,
            value: preview.worked.formatHoursMinutes(context),
          ),
          InfoRow(
            label: l10n.observedOvertime,
            value: preview.overtime.formatHoursMinutes(context),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          key: const Key('editReason'),
          controller: _reason,
          enabled: !saving,
          minLines: 2,
          maxLines: 4,
          maxLength: CorrectionRules.maxTextLength,
          decoration: InputDecoration(
            labelText: l10n.correctionReason,
            hintText: l10n.adminEditReasonHint,
          ),
        ),
        if (state.failure case final failure?)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              failure.message(l10n),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.error,
              ),
            ),
          ),
        AppPrimaryButton(
          key: const Key('saveTimes'),
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.adminSaveTimes),
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 16,
      verticalPadding: 14,
      onTap: onTap,
      child: Row(
        spacing: 10,
        children: [
          Icon(Icons.access_time_rounded, color: context.colors.primary),
          Expanded(child: Text(label, style: context.textTheme.labelLarge)),
          Text(value, style: context.textTheme.labelLarge),
        ],
      ),
    );
  }
}
