import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/correction_errors.dart';
import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../attendance_session/domain/repositories/attendance_repository.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';
import '../../domain/correction_rules.dart';
import '../../domain/entities/correction_request_entity.dart';
import '../../domain/repositories/correction_repository.dart';
import '../widgets/correction_request_details.dart';
import '../widgets/correction_text.dart';

sealed class MyCorrectionsState {
  const MyCorrectionsState();
}

final class MyCorrectionsLoading extends MyCorrectionsState {
  const MyCorrectionsLoading();
}

final class MyCorrectionsError extends MyCorrectionsState {
  const MyCorrectionsError(this.failure);
  final CorrectionFailure failure;
}

final class MyCorrectionsLoaded extends MyCorrectionsState {
  const MyCorrectionsLoaded(this.requests);

  /// Newest first.
  final List<CorrectionRequestEntity> requests;
}

/// The signed-in employee's own correction requests, every status.
class MyCorrectionsCubit extends Cubit<MyCorrectionsState> {
  MyCorrectionsCubit(this._repository) : super(const MyCorrectionsLoading());

  final CorrectionRepository _repository;

  /// Only the newest load may emit.
  int _loadId = 0;

  /// A failed refresh keeps the list that is shown.
  Future<void> load() async {
    final loadId = ++_loadId;
    if (state is! MyCorrectionsLoaded) emit(const MyCorrectionsLoading());
    try {
      final requests = await _repository.getMine();
      if (isClosed || loadId != _loadId) return;
      emit(MyCorrectionsLoaded(requests));
    } on CorrectionFailure catch (failure) {
      if (isClosed || loadId != _loadId) return;
      if (state is! MyCorrectionsLoaded) emit(MyCorrectionsError(failure));
    }
  }
}

/// Opened from Home, beside cash requests: the employee's correction
/// requests with their status and the reviewer's note, and a way to send a
/// new one for a closed day.
///
/// A correction always fixes the times of a day that has a check-in: the
/// database has no request for a day without one.
class MyCorrectionsView extends StatelessWidget {
  const MyCorrectionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) =>
          MyCorrectionsCubit(context.read<CorrectionRepository>())..load(),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Builder(
              builder: (context) => Column(
                spacing: 16,
                children: [
                  customAppBar(
                    context: context,
                    title: l10n.correctionRequests,
                    leading: CustomBackButton(),
                  ),
                  Expanded(
                    child: BlocBuilder<MyCorrectionsCubit, MyCorrectionsState>(
                      builder: (context, state) => switch (state) {
                        MyCorrectionsLoading() => AppLoadingView(
                          title: l10n.correctionRequests,
                          message: '',
                        ),
                        MyCorrectionsError(:final failure) => AppErrorView(
                          title: l10n.correctionLoadFailed,
                          message: failure.message(l10n),
                          onRetry: context.read<MyCorrectionsCubit>().load,
                        ),
                        MyCorrectionsLoaded(:final requests)
                            when requests.isEmpty =>
                          AppEmptyView(
                            title: l10n.myCorrectionsEmptyTitle,
                            message: l10n.myCorrectionsEmptyMessage,
                            actionLabel: null,
                          ),
                        MyCorrectionsLoaded(:final requests) =>
                          RefreshIndicator(
                            onRefresh: context.read<MyCorrectionsCubit>().load,
                            child: ListView.separated(
                              itemCount: requests.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _RequestCard(request: requests[index]),
                            ),
                          ),
                      },
                    ),
                  ),
                  AppPrimaryButton(
                    key: const Key('newCorrection'),
                    onPressed: () => _newRequest(context),
                    child: Text(l10n.correctionNewRequest),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Picks one of the employee's closed days, opens the request form for
  /// it, and reloads the list afterwards.
  Future<void> _newRequest(BuildContext context) async {
    final cubit = context.read<MyCorrectionsCubit>();
    final days = context.read<AttendanceRepository>().getHistory();
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DayPicker(days: days),
    );
    if (id == null || !context.mounted) return;
    await context.push(AppRoutes.attendanceCorrectionOf(id));
    await cubit.load();
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final CorrectionRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date =
        request.workDate ??
        CorrectionRules.wallClock(request.timezone, request.proposedCheckIn);
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 16,
      verticalPadding: 16,
      onTap: () =>
          context.push(AppRoutes.attendanceDetailsOf(request.attendanceId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  date.formatFullDate(context),
                  style: context.textTheme.titleMedium,
                ),
              ),
              CustomStatusContainer(
                tone: request.status.tone,
                text: request.status.label(l10n),
              ),
            ],
          ),
          Text(
            l10n.correctionSentOn(request.createdAt.formatShortDate(context)),
            style: AppTextStyles.meta.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          CorrectionRequestDetails(
            request: request,
            timezone: request.timezone,
          ),
        ],
      ),
    );
  }
}

/// The employee's closed days (checked out, or closed automatically): the
/// only days `request_attendance_correction` accepts.
class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.days});

  final Future<List<AttendanceSessionEntity>> days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: FutureBuilder<List<AttendanceSessionEntity>>(
          future: days,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.historyLoadFailed),
              );
            }
            final all = snapshot.data;
            if (all == null) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final closed = [
              for (final day in all)
                if (day.checkOut != null || day.isAutoClosed) day,
            ];
            return ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    l10n.correctionPickDay,
                    style: context.textTheme.titleMedium,
                  ),
                ),
                if (closed.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text(l10n.correctionNoDays),
                  ),
                for (final day in closed)
                  ListTile(
                    key: Key('day-${day.id}'),
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      (day.workDate ?? day.checkInTime).formatFullDate(context),
                    ),
                    // The kind of fix the day needs, from what it recorded.
                    subtitle: Text(
                      day.checkOut == null
                          ? l10n.correctionTypeMissingCheckOut
                          : l10n.correctionTypeTimes,
                    ),
                    onTap: () => Navigator.pop(context, day.id),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
