import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/feedback/app_dialog.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../admin/presentation/widgets/admin_failure_text.dart';
import '../../domain/entities/permission_set.dart';
import '../../domain/repositories/permission_repository.dart';
import '../manager/manage_permissions_cubit.dart';
import '../manager/permissions_cubit.dart';

/// Admin only: one employee's permissions (the reviewer flags of the live
/// database), grouped, with what each one allows. Saving shows the changes
/// first. Admin accounts are shown locked: they review through their role.
class ManagePermissionsView extends StatelessWidget {
  const ManagePermissionsView({super.key, required this.employeeId, this.name});

  final String employeeId;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) => ManagePermissionsCubit(
        context.read<PermissionRepository>(),
        employeeId,
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
                  title: name == null
                      ? l10n.permissionsTitle
                      : '${l10n.permissionsTitle} · $name',
                  leading: CustomBackButton(),
                ),
                Expanded(
                  child:
                      BlocBuilder<
                        ManagePermissionsCubit,
                        ManagePermissionsState
                      >(
                        builder: (context, state) => switch (state) {
                          ManagePermissionsLoading() => AppLoadingView(
                            title: l10n.permissionsTitle,
                            message: '',
                          ),
                          ManagePermissionsError(:final failure) =>
                            AppErrorView(
                              title: l10n.adminLoadFailed,
                              message: failure.message(l10n),
                              onRetry: context
                                  .read<ManagePermissionsCubit>()
                                  .load,
                            ),
                          ManagePermissionsLoaded() => _Editor(
                            state: state,
                            name: name ?? '',
                          ),
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

/// The readable name of a permission code.
String permissionLabel(AppLocalizations l10n, String code) => switch (code) {
  Permission.attendanceViewAll => l10n.permAttendanceViewAll,
  Permission.correctionsView => l10n.permCorrectionsView,
  Permission.correctionsApprove => l10n.permCorrectionsApprove,
  Permission.correctionsReject => l10n.permCorrectionsReject,
  Permission.attendanceEdit => l10n.permAttendanceEdit,
  Permission.scheduleEdit => l10n.permScheduleEdit,
  Permission.cashViewAll => l10n.permCashViewAll,
  Permission.cashApprove => l10n.permCashApprove,
  Permission.cashReject => l10n.permCashReject,
  Permission.employeesView => l10n.permEmployeesView,
  Permission.employeesEdit => l10n.permEmployeesEdit,
  Permission.managePermissions => l10n.permManagePermissions,
  Permission.reportsView => l10n.permReportsView,
  Permission.reportsExport => l10n.permReportsExport,
  Permission.auditView => l10n.permAuditView,
  Permission.reviewAssignedCash => l10n.permReviewAssignedCash,
  Permission.reviewAssignedCorrections => l10n.permReviewAssignedCorrections,
  Permission.reviewAssignedOvertime => l10n.permReviewAssignedOvertime,
  // A code added in the database before the app knows it.
  _ => code,
};

/// What holding a delegable code means, shown under its switch.
String? permissionDescription(AppLocalizations l10n, String code) =>
    switch (code) {
      Permission.reviewAssignedOvertime => l10n.permOvertimeUnusedHint,
      _ when Permission.delegable.containsKey(code) =>
        l10n.permReviewAssignedHint,
      _ => null,
    };

String _categoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'attendance' => l10n.permissionsCategoryAttendance,
      'cash' => l10n.permissionsCategoryCash,
      'employees' => l10n.permissionsCategoryEmployees,
      'reports' => l10n.permissionsCategoryReports,
      _ => category,
    };

class _Editor extends StatelessWidget {
  const _Editor({required this.state, required this.name});

  final ManagePermissionsLoaded state;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = <String, List<PermissionEntry>>{};
    for (final entry in state.entries) {
      categories.putIfAbsent(entry.category, () => []).add(entry);
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(
                l10n.permissionsIntro(name),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              for (final MapEntry(key: category, value: entries)
                  in categories.entries) ...[
                const SizedBox(height: 16),
                Text(
                  _categoryLabel(l10n, category),
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                CustomContainer(
                  borderWidth: 1,
                  horizontalPadding: 4,
                  verticalPadding: 4,
                  // Own Material layer: the card's color would hide the
                  // tiles' tap ripple.
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      children: [
                        for (final entry in entries)
                          _PermissionTile(entry: entry, state: state),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppPrimaryButton(
          key: const Key('savePermissions'),
          onPressed: state.saving || !state.hasChanges
              ? null
              : () => _save(context),
          child: state.saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.permissionsSave),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<ManagePermissionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    String list(Set<String> codes) =>
        codes.map((code) => '• ${permissionLabel(l10n, code)}').join('\n');
    final confirmed = await showAppConfirmationDialog(
      context,
      title: l10n.permissionsConfirmTitle,
      message: [
        if (state.added.isNotEmpty)
          '${l10n.permissionsAdded}:\n${list(state.added)}',
        if (state.removed.isNotEmpty)
          '${l10n.permissionsRemoved}:\n${list(state.removed)}',
      ].join('\n\n'),
      confirmLabel: l10n.permissionsSave,
      cancelLabel: l10n.correctionCancel,
      type: AppMessageType.info,
    );
    if (!confirmed) return;
    final failure = await cubit.save();
    showAppSnackBar(
      messenger,
      failure == null ? l10n.permissionsSaved : failure.message(l10n),
      type: failure == null ? AppMessageType.success : AppMessageType.error,
    );
    // The manager's own view of the admin area may depend on it too.
    if (failure == null && context.mounted) {
      context.read<PermissionsCubit>().refresh();
    }
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.entry, required this.state});

  final PermissionEntry entry;
  final ManagePermissionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = entry.fromRole || state.selected.contains(entry.code);
    final note = entry.fromRole
        ? l10n.permissionsFromRole
        : !entry.canChange
        ? (entry.sensitive
              ? l10n.permissionsSensitive
              : l10n.permissionsNotYours)
        : entry.granted && entry.grantedAt != null
        ? l10n.permissionsGrantedOn(entry.grantedAt!.formatShortDate(context))
        : permissionDescription(l10n, entry.code);
    return SwitchListTile(
      key: Key('permission-${entry.code}'),
      value: on,
      onChanged: entry.fromRole || !entry.canChange || state.saving
          ? null
          : (value) => context.read<ManagePermissionsCubit>().toggle(
              entry.code,
              value,
            ),
      title: Text(
        permissionLabel(l10n, entry.code),
        style: context.textTheme.bodyLarge,
      ),
      subtitle: note == null
          ? null
          : Text(
              note,
              style: AppTextStyles.meta.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
      secondary: entry.sensitive
          ? Icon(
              Icons.shield_outlined,
              color: context.appColors.warning,
              semanticLabel: l10n.permissionsSensitive,
            )
          : null,
    );
  }
}
