import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import '../../../attendance_correction/presentation/widgets/review_decision_dialog.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../domain/entities/admin_request_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../manager/admin_requests_cubit/admin_requests_cubit.dart';
import '../widgets/admin_failure_text.dart';

/// Admin only: pending cash requests to approve or reject.
class AdminRequestsView extends StatelessWidget {
  const AdminRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) =>
          AdminRequestsCubit(context.read<AdminRepository>())..load(),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
          child: Column(
            spacing: 16,
            children: [
              customAppBar(
                context: context,
                title: l10n.adminRequests,
                leading: CustomBackButton(),
              ),
              Expanded(
                child: BlocBuilder<AdminRequestsCubit, AdminRequestsState>(
                  builder: (context, state) => switch (state) {
                    AdminRequestsLoading() => AppLoadingView(
                      title: l10n.adminRequests,
                      message: '',
                    ),
                    AdminRequestsError() => AppErrorView(
                      title: l10n.adminLoadFailed,
                      message: l10n.authNetworkError,
                      onRetry: context.read<AdminRequestsCubit>().load,
                    ),
                    AdminRequestsLoaded(:final requests)
                        when requests.isEmpty =>
                      AppEmptyView(
                        title: l10n.adminCorrectionsEmptyTitle,
                        message: l10n.adminRequestsEmptyMessage,
                        actionLabel: null,
                      ),
                    AdminRequestsLoaded(:final requests, :final reviewing) =>
                      RefreshIndicator(
                        onRefresh: context.read<AdminRequestsCubit>().load,
                        child: ListView.separated(
                          itemCount: requests.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => _RequestCard(
                            request: requests[index],
                            reviewing: reviewing.contains(requests[index].id),
                          ),
                        ),
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.reviewing});

  final AdminRequestEntity request;
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
            [?request.employeeName, ?request.employeeCode].join(' · '),
            style: context.textTheme.titleMedium,
          ),
          InfoRow(
            label: l10n.adminCashRequest,
            value: '${request.amount} ${request.currency}',
          ),
          InfoRow(
            label: l10n.adminSubmitted,
            value: request.createdAt.formatShortDate(context),
          ),
          Text(
            '${l10n.correctionReason}: ${request.reason}',
            style: context.textTheme.bodyMedium,
          ),
          if (reviewing)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('reject-${request.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.error,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: () => _review(context, approve: false),
                    child: Text(l10n.correctionReject),
                  ),
                ),
                Expanded(
                  child: AppPrimaryButton(
                    key: Key('approve-${request.id}'),
                    onPressed: () => _review(context, approve: true),
                    child: Text(l10n.correctionApprove),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _review(BuildContext context, {required bool approve}) async {
    final l10n = context.l10n;
    final cubit = context.read<AdminRequestsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final note = await showReviewDecisionDialog(
      context,
      approve: approve,
      title: approve
          ? l10n.adminApproveRequestTitle
          : l10n.adminRejectRequestTitle,
      message: request.reason,
    );
    if (note == null) return;
    final failure = await cubit.review(request, approve: approve, note: note);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure?.message(l10n) ??
              (approve ? l10n.adminRequestApproved : l10n.adminRequestRejected),
        ),
      ),
    );
  }
}
