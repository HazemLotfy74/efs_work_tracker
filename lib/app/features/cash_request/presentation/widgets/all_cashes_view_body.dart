import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/errors/request_failure_text.dart';
import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../../../core/widgets/text_icon_widget.dart';
import '../../../attendance_session/presentation/widgets/custom_app_header.dart';
import '../../../../../core/widgets/requests/request_filter_widget.dart';
import '../../domain/entities/expense_advance_request_entity.dart';
import '../manager/cash_requests_cubit/cash_requests_cubit.dart';
import 'cash_request_container.dart';
import 'money_text.dart';

class AllCashesViewBody extends StatelessWidget {
  const AllCashesViewBody({super.key});

  /// Opens the form, then reloads the list.
  Future<void> _create(BuildContext context) async {
    final cubit = context.read<CashRequestsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final request = await context.push<ExpenseAdvanceRequestEntity>(
      AppRoutes.newCashRequest,
    );
    cubit.load();
    if (request != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.cashSubmittedMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CashRequestsCubit, CashRequestsState>(
      builder: (context, state) {
        final cubit = context.read<CashRequestsCubit>();
        return RefreshIndicator(
          onRefresh: cubit.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 20,
                  children: [
                    CustomAppHeader(
                      title: l10n.cashRequests,
                      trailing: CustomContainer(
                        onTap: () => _create(context),
                        borderWidth: 1,
                        child: const Icon(Icons.add),
                      ),
                    ),
                    CustomContainer(
                      containerColor: context.colors.onSurface,
                      containerWidth: double.infinity,
                      borderWidth: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 5,
                        children: [
                          Text(
                            l10n.pendingRequests,
                            style: context.textTheme.bodyMedium!.copyWith(
                              color: context.colors.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _pendingText(context, state),
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodyLarge!.copyWith(
                              color: context.colors.surface,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RequestFilterWidget(
                      selected: state.filter,
                      onChanged: cubit.filterBy,
                    ),
                    Text(
                      l10n.recentRequests,
                      style: context.textTheme.bodyMedium!.copyWith(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _requests(context, state),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: AppPrimaryButton(
                  onPressed: () => _create(context),
                  child: TextIconWidget(
                    txt: l10n.newCashRequest,
                    icon: Icons.add,
                    style: context.textTheme.bodyMedium!.copyWith(
                      color: context.colors.surface,
                      fontWeight: FontWeight.w800,
                    ),
                    iconColor: context.colors.surface,
                    iconSize: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pending total per currency, e.g. "250 EGP"; "--" until loaded.
  static String _pendingText(BuildContext context, CashRequestsState state) {
    if (state is! CashRequestsLoaded) return '--';
    final totals = state.pendingTotals;
    if (totals.isEmpty) {
      return formatMoney(context, 0, ExpenseAdvanceDraft.defaultCurrency);
    }
    return totals.entries
        .map((total) => formatMoney(context, total.value, total.key))
        .join(' + ');
  }

  /// The list, or a message in its place.
  Widget _requests(BuildContext context, CashRequestsState state) {
    final l10n = context.l10n;
    // The state views need a bounded height.
    Widget message(Widget child) =>
        SliverToBoxAdapter(child: SizedBox(height: 420, child: child));
    return switch (state) {
      CashRequestsLoading() => message(
        AppLoadingView(title: l10n.cashRequests, message: ''),
      ),
      CashRequestsError(:final failure) => message(
        AppErrorView(
          title: l10n.cashLoadFailed,
          message: failure.message(l10n),
          onRetry: context.read<CashRequestsCubit>().load,
        ),
      ),
      CashRequestsLoaded(:final visible) when visible.isEmpty => message(
        AppEmptyView(
          title: l10n.cashEmptyTitle,
          message: l10n.cashEmptyMessage,
          icon: Icons.payments_outlined,
          actionLabel: null,
        ),
      ),
      CashRequestsLoaded(:final visible) => SliverList.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            CashRequestContainer(request: visible[index]),
        itemCount: visible.length,
      ),
    };
  }
}
