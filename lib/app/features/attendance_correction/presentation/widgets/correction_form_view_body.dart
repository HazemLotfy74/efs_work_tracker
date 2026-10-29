import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../home/presentation/manager/attendance_details_cubit/attendance_details_cubit.dart';
import '../../domain/correction_rules.dart';
import '../manager/correction_form_cubit/correction_form_cubit.dart';
import 'correction_text.dart';

class CorrectionFormViewBody extends StatelessWidget {
  const CorrectionFormViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      spacing: 20,
      children: [
        customAppBar(
          context: context,
          title: l10n.correctionTitle,
          leading: CustomBackButton(),
        ),
        Expanded(
          child: BlocBuilder<AttendanceDetailsCubit, AttendanceDetailsState>(
            builder: (context, state) => switch (state) {
              AttendanceDetailsLoading() => AppLoadingView(
                title: l10n.correctionTitle,
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
              AttendanceDetailsLoaded(:final session)
                  when session.checkOut == null && !session.isAutoClosed =>
                AppEmptyView(
                  title: l10n.correctionNotClosed,
                  message: '',
                  actionLabel: null,
                ),
              AttendanceDetailsLoaded(:final session) => _CorrectionForm(
                session: session,
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _CorrectionForm extends StatefulWidget {
  const _CorrectionForm({required this.session});

  final AttendanceSessionEntity session;

  @override
  State<_CorrectionForm> createState() => _CorrectionFormState();
}

class _CorrectionFormState extends State<_CorrectionForm> {
  final _reason = TextEditingController();

  /// Wall-clock times of day on the work date, in the day's timezone.
  late Duration? _checkIn = CorrectionRules.timeOfDay(
    widget.session.timezone,
    widget.session.checkInTime,
  );
  Duration? _checkOut;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool checkIn}) async {
    final current =
        (checkIn ? _checkIn : _checkOut) ??
        CorrectionRules.timeOfDay(
          widget.session.timezone,
          widget.session.scheduledEnd,
        );
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.inHours,
        minute: current.inMinutes.remainder(60),
      ),
    );
    if (picked == null || !mounted) return;
    final time = Duration(hours: picked.hour, minutes: picked.minute);
    setState(() => checkIn ? _checkIn = time : _checkOut = time);
  }

  void _submit() {
    final session = widget.session;
    DateTime? at(Duration? time) =>
        time == null ? null : CorrectionRules.onWorkDate(session, time);
    context.read<CorrectionFormCubit>().submit(
      session,
      checkIn: at(_checkIn),
      checkOut: at(_checkOut),
      reason: _reason.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = widget.session;
    final date = session.workDate ?? session.checkInTime;
    final timezone = session.timezone;

    return BlocConsumer<CorrectionFormCubit, CorrectionFormState>(
      listener: (context, state) {
        if (state is CorrectionFormSubmitted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.correctionSubmitted)));
          context.pop(true);
        }
      },
      builder: (context, state) {
        final submitting = state is CorrectionFormSubmitting;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              CustomContainer(
                borderWidth: 1,
                containerColor: context.appColors.warningContainer,
                horizontalPadding: 16,
                verticalPadding: 14,
                child: Text(
                  l10n.correctionIntro,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.warning,
                  ),
                ),
              ),
              Text(
                date.formatFullDate(context),
                style: context.textTheme.titleMedium,
              ),
              _TimeField(
                key: const Key('correctionCheckIn'),
                label: l10n.correctionCheckIn,
                time: _checkIn,
                onTap: submitting ? null : () => _pick(checkIn: true),
              ),
              _TimeField(
                key: const Key('correctionCheckOut'),
                label: l10n.correctionCheckOut,
                time: _checkOut,
                onTap: submitting ? null : () => _pick(checkIn: false),
              ),
              if (timezone != null)
                Text(
                  l10n.correctionTimezoneNote(timezone),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              Text(
                l10n.correctionReason,
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.appColors.fieldLabelText,
                ),
              ),
              TextField(
                key: const Key('correctionReason'),
                controller: _reason,
                enabled: !submitting,
                minLines: 3,
                maxLines: 6,
                maxLength: CorrectionRules.maxTextLength,
                decoration: InputDecoration(
                  hintText: l10n.correctionReasonHint,
                ),
              ),
              if (state case CorrectionFormFailed(:final failure))
                Text(
                  failure.message(l10n),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              AppPrimaryButton(
                onPressed: submitting ? null : _submit,
                child: submitting
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.correctionSubmit),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    super.key,
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final Duration? time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = this.time;
    final value = time == null
        ? context.l10n.correctionPickTime
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(hour: time.inHours, minute: time.inMinutes.remainder(60)),
            alwaysUse24HourFormat:
                MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false,
          );
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
          Text(
            value,
            style: context.textTheme.labelLarge?.copyWith(
              color: time == null
                  ? context.colors.onSurfaceVariant
                  : context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
