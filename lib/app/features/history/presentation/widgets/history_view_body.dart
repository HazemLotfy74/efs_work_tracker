import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../manager/attendance_history_cubit/attendance_history_cubit.dart';
import 'attendance_history_tile.dart';

class HistoryViewBody extends StatelessWidget {
  const HistoryViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(l10n.history, style: context.textTheme.headlineSmall),
        Expanded(
          child: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
            builder: (context, state) => switch (state) {
              AttendanceHistoryLoading() => AppLoadingView(
                title: l10n.history,
                message: '',
              ),
              AttendanceHistoryError() => AppErrorView(
                title: l10n.historyLoadFailed,
                message: l10n.authNetworkError,
                onRetry: context.read<AttendanceHistoryCubit>().load,
              ),
              AttendanceHistoryLoaded(:final sessions) when sessions.isEmpty =>
                AppEmptyView(
                  title: l10n.historyEmptyTitle,
                  message: l10n.historyEmptyMessage,
                  actionLabel: null,
                ),
              AttendanceHistoryLoaded(:final sessions) => RefreshIndicator(
                onRefresh: context.read<AttendanceHistoryCubit>().load,
                child: ListView.separated(
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      AttendanceHistoryTile(session: sessions[index]),
                ),
              ),
            },
          ),
        ),
      ],
    );
  }
}
