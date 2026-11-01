import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/audit_entry_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../manager/audit_history_cubit/audit_history_cubit.dart';

/// Admin only: the database's own record of every change to an employee's
/// profile, attendance days, requests and corrections. Read-only: the log
/// is append-only in the database.
class AuditHistoryView extends StatelessWidget {
  const AuditHistoryView({super.key, required this.employeeId, this.name});

  final String employeeId;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) =>
          AuditHistoryCubit(context.read<AdminRepository>(), employeeId)
            ..load(),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            spacing: 16,
            children: [
              customAppBar(
                context: context,
                title: name == null
                    ? l10n.adminAuditHistory
                    : '${l10n.adminAuditHistory} · $name',
                leading: CustomBackButton(),
              ),
              Expanded(
                child: BlocBuilder<AuditHistoryCubit, AuditHistoryState>(
                  builder: (context, state) => switch (state) {
                    AuditHistoryLoading() => AppLoadingView(
                      title: l10n.adminAuditHistory,
                      message: '',
                    ),
                    AuditHistoryError() => AppErrorView(
                      title: l10n.adminLoadFailed,
                      message: l10n.authNetworkError,
                      onRetry: context.read<AuditHistoryCubit>().load,
                    ),
                    AuditHistoryLoaded(:final entries) when entries.isEmpty =>
                      AppEmptyView(
                        title: l10n.adminAuditEmpty,
                        message: '',
                        actionLabel: null,
                      ),
                    AuditHistoryLoaded(:final entries, :final names) =>
                      ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _EntryTile(entry: entries[index], names: names),
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

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.names});

  final AuditEntryEntity entry;
  final Map<String, String> names;

  static String _table(AppLocalizations l10n, String table) => switch (table) {
    'profiles' => l10n.adminAuditTableProfile,
    'attendance_records' => l10n.adminAuditTableAttendance,
    'attendance_events' => l10n.adminAuditTableEvidence,
    'expense_advance_requests' => l10n.adminAuditTableCash,
    'attendance_correction_requests' => l10n.adminAuditTableCorrection,
    'overtime_requests' => l10n.adminAuditTableOvertime,
    _ => table,
  };

  static String _action(AppLocalizations l10n, String action) =>
      switch (action) {
        'INSERT' => l10n.adminAuditCreated,
        'DELETE' => l10n.adminAuditDeleted,
        _ => l10n.adminAuditChanged,
      };

  static String _value(Object? value) => switch (value) {
    null => '—',
    final String text => text,
    _ => '$value',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actor = entry.actorId;
    final who = actor == null
        ? l10n.adminAuditSystem
        : names[actor] ?? actor.substring(0, 8);
    // An insert lists every column; show only what a reviewer needs.
    final changes = entry.action == 'INSERT'
        ? entry.changes.take(6).toList()
        : entry.changes;
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 14,
      verticalPadding: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            '${_action(l10n, entry.action)} · ${_table(l10n, entry.table)}',
            style: context.textTheme.labelLarge,
          ),
          Text(
            '${entry.happenedAt.formatShortDate(context)} '
            '${entry.happenedAt.formatTime(context)} · '
            '${l10n.adminAuditBy(who)}',
            style: AppTextStyles.meta.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          for (final change in changes)
            Text(
              entry.action == 'INSERT'
                  ? '${change.field}: ${_value(change.after)}'
                  : '${change.field}: ${_value(change.before)} → '
                        '${_value(change.after)}',
              style: context.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
