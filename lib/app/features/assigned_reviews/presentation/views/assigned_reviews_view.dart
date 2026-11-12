import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/admin_errors.dart';
import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../admin/presentation/widgets/admin_failure_text.dart';
import '../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../attendance_correction/presentation/widgets/correction_request_details.dart';
import '../../../attendance_correction/presentation/widgets/review_decision_dialog.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../../cash_request/domain/entities/expense_advance_request_entity.dart';
import '../../../cash_request/presentation/widgets/money_text.dart';
import '../../../permissions/domain/entities/permission_set.dart';
import '../../../permissions/presentation/manager/permissions_cubit.dart';
import '../../../permissions/presentation/permissions_context.dart';
import '../../domain/repositories/assigned_review_repository.dart';
import '../manager/assigned_reviews_cubit.dart';

/// For an employee who holds a review permission: the pending requests an
/// admin assigned to them, with Approve and Reject. Showing it is not the
/// security boundary: the database only returns assigned rows and the
/// `review_assigned_*` functions check the permission on every decision.
class AssignedReviewsView extends StatelessWidget {
  const AssignedReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final can = context.permissions;
    return BlocProvider(
      // Rebuilt when the permissions change, so a removed one stops loading.
      key: ValueKey(can),
      create: (context) => AssignedReviewsCubit(
        context.read<AssignedReviewRepository>(),
        loadCash: can.can(Permission.reviewAssignedCash),
        loadCorrections: can.can(Permission.reviewAssignedCorrections),
      )..load(),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              spacing: 16,
              children: [
                customAppBar(
                  context: context,
                  title: l10n.assignedReviews,
                  leading: CustomBackButton(),
                ),
                Expanded(
                  child:
                      BlocBuilder<AssignedReviewsCubit, AssignedReviewsState>(
                        builder: (context, state) => switch (state) {
                          AssignedReviewsLoading() => AppLoadingView(
                            title: l10n.assignedReviews,
                            message: '',
                          ),
                          AssignedReviewsError(:final failure) => AppErrorView(
                            title: l10n.assignedReviewsLoadFailed,
                            message: failure.message(l10n),
                            onRetry: context.read<AssignedReviewsCubit>().load,
                          ),
                          AssignedReviewsLoaded() when state.isEmpty =>
                            AppEmptyView(
                              title: l10n.adminCorrectionsEmptyTitle,
                              message: l10n.assignedReviewsEmpty,
                              actionLabel: null,
                            ),
                          AssignedReviewsLoaded() => _Lists(state: state),
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Lists extends StatelessWidget {
  const _Lists({required this.state});

  final AssignedReviewsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AssignedReviewsCubit>();
    Widget header(String text) => Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(text, style: context.textTheme.titleSmall),
    );
    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text(
            l10n.assignedRequesterHidden,
            style: AppTextStyles.meta.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (state.cash.isNotEmpty) header(l10n.adminRequests),
          for (final request in state.cash) ...[
            _CashCard(
              request: request,
              reviewing: state.reviewing.contains(request.id),
            ),
            const SizedBox(height: 12),
          ],
          if (state.corrections.isNotEmpty) header(l10n.adminCorrections),
          for (final request in state.corrections) ...[
            _CorrectionCard(
              request: request,
              reviewing: state.reviewing.contains(request.id),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _CashCard extends StatelessWidget {
  const _CashCard({required this.request, required this.reviewing});

  final ExpenseAdvanceRequestEntity request;
  final bool reviewing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 16,
      verticalPadding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            formatMoney(context, request.amount, request.currency),
            style: context.textTheme.titleMedium,
          ),
          InfoRow(
            label: l10n.adminSubmitted,
            value: request.createdAt.formatShortDate(context),
          ),
          Text(
            '${l10n.correctionReason}: ${request.reason}',
            style: context.textTheme.bodyMedium,
          ),
          _Decision(
            id: request.id,
            reviewing: reviewing,
            approveTitle: l10n.adminApproveRequestTitle,
            rejectTitle: l10n.adminRejectRequestTitle,
            message: (_) => request.reason,
            send: (cubit, approve, note) =>
                cubit.reviewCash(request.id, approve: approve, note: note),
          ),
        ],
      ),
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.request, required this.reviewing});

  final CorrectionRequestEntity request;
  final bool reviewing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final workDate = request.workDate;
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 16,
      verticalPadding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            // The day itself is only readable by admins; the proposed
            // check-in is on the same work date.
            (workDate ?? request.proposedCheckIn).formatFullDate(context),
            style: context.textTheme.titleMedium,
          ),
          Text(
            l10n.correctionProposedTimes,
            style: context.textTheme.labelMedium,
          ),
          CorrectionRequestDetails(
            request: request,
            timezone: request.timezone,
          ),
          _Decision(
            id: request.id,
            reviewing: reviewing,
            approveTitle: l10n.correctionApproveTitle,
            rejectTitle: l10n.correctionRejectTitle,
            message: (approve) => approve
                ? l10n.correctionApproveMessage
                : l10n.correctionRejectMessage,
            send: (cubit, approve, note) => cubit.reviewCorrection(
              request.id,
              approve: approve,
              note: note,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reject and Approve, each confirmed with an optional note.
class _Decision extends StatelessWidget {
  const _Decision({
    required this.id,
    required this.reviewing,
    required this.approveTitle,
    required this.rejectTitle,
    required this.message,
    required this.send,
  });

  final String id;
  final bool reviewing;
  final String approveTitle;
  final String rejectTitle;
  final String Function(bool approve) message;
  final Future<AdminFailure?> Function(
    AssignedReviewsCubit cubit,
    bool approve,
    String? note,
  )
  send;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (reviewing) return const Center(child: CircularProgressIndicator());
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: OutlinedButton(
            key: Key('reject-$id'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.error,
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: () => _decide(context, approve: false),
            child: Text(l10n.correctionReject),
          ),
        ),
        Expanded(
          child: AppPrimaryButton(
            key: Key('approve-$id'),
            onPressed: () => _decide(context, approve: true),
            child: Text(l10n.correctionApprove),
          ),
        ),
      ],
    );
  }

  Future<void> _decide(BuildContext context, {required bool approve}) async {
    final l10n = context.l10n;
    final cubit = context.read<AssignedReviewsCubit>();
    final permissions = context.read<PermissionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final note = await showReviewDecisionDialog(
      context,
      approve: approve,
      title: approve ? approveTitle : rejectTitle,
      message: message(approve),
    );
    if (note == null) return;
    final failure = await send(cubit, approve, note);
    // The permission was removed meanwhile: the router then leaves this
    // screen and Home hides its shortcut.
    if (failure == AdminFailure.notAllowed) await permissions.refresh();
    showAppSnackBar(
      messenger,
      failure?.message(l10n) ??
          (approve ? l10n.adminRequestApproved : l10n.adminRequestRejected),
      type: failure == null ? AppMessageType.success : AppMessageType.error,
    );
  }
}
