import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../domain/repositories/admin_repository.dart';
import '../manager/employee_history_cubit/employee_history_cubit.dart';
import '../widgets/admin_day_status.dart';

/// Admin only: one employee's attendance days.
class EmployeeHistoryView extends StatelessWidget {
  const EmployeeHistoryView({super.key, required this.id, this.name});

  final String id;

  /// Shown as the title when the dashboard passed it.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) =>
          EmployeeHistoryCubit(context.read<AdminRepository>(), id)..load(),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
          child: Column(
            spacing: 16,
            children: [
              customAppBar(
                context: context,
                title: name ?? l10n.history,
                leading: CustomBackButton(),
              ),
              Expanded(
                child: BlocBuilder<EmployeeHistoryCubit, EmployeeHistoryState>(
                  builder: (context, state) => switch (state) {
                    EmployeeHistoryLoading() => AppLoadingView(
                      title: l10n.history,
                      message: '',
                    ),
                    EmployeeHistoryError() => AppErrorView(
                      title: l10n.historyLoadFailed,
                      message: l10n.authNetworkError,
                      onRetry: context.read<EmployeeHistoryCubit>().load,
                    ),
                    EmployeeHistoryLoaded(:final sessions)
                        when sessions.isEmpty =>
                      AppEmptyView(
                        title: l10n.adminHistoryEmpty,
                        message: '',
                        actionLabel: null,
                      ),
                    EmployeeHistoryLoaded(:final sessions) => RefreshIndicator(
                      onRefresh: context.read<EmployeeHistoryCubit>().load,
                      child: ListView.separated(
                        itemCount: sessions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final now = context.watch<ClockCubit>().state;
                          final date = session.workDate ?? session.checkInTime;
                          return CustomContainer(
                            borderWidth: 1,
                            horizontalPadding: 14,
                            verticalPadding: 12,
                            child: Row(
                              spacing: 12,
                              children: [
                                Expanded(
                                  child: Text(
                                    date.formatShortDate(context),
                                    style: context.textTheme.labelLarge,
                                  ),
                                ),
                                Flexible(
                                  child: AdminDayStatus(
                                    session: session,
                                    now: now,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
