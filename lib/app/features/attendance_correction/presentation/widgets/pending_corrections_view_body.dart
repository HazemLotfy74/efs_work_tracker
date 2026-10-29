import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../manager/pending_corrections_cubit/pending_corrections_cubit.dart';
import 'correction_review_card.dart';

class PendingCorrectionsViewBody extends StatelessWidget {
  const PendingCorrectionsViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      spacing: 20,
      children: [
        customAppBar(
          context: context,
          title: l10n.adminCorrections,
          leading: CustomBackButton(),
        ),
        Expanded(
          child: BlocBuilder<PendingCorrectionsCubit, PendingCorrectionsState>(
            builder: (context, state) => switch (state) {
              PendingCorrectionsLoading() => AppLoadingView(
                title: l10n.adminCorrections,
                message: '',
              ),
              PendingCorrectionsError() => AppErrorView(
                title: l10n.adminCorrectionsLoadFailed,
                message: l10n.authNetworkError,
                onRetry: context.read<PendingCorrectionsCubit>().load,
              ),
              PendingCorrectionsLoaded(:final requests) when requests.isEmpty =>
                AppEmptyView(
                  title: l10n.adminCorrectionsEmptyTitle,
                  message: l10n.adminCorrectionsEmptyMessage,
                  actionLabel: null,
                ),
              PendingCorrectionsLoaded(:final requests, :final reviewing) =>
                RefreshIndicator(
                  onRefresh: context.read<PendingCorrectionsCubit>().load,
                  child: ListView.separated(
                    itemCount: requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => CorrectionReviewCard(
                      request: requests[index],
                      reviewing: reviewing.contains(requests[index].id),
                    ),
                  ),
                ),
            },
          ),
        ),
      ],
    );
  }
}
