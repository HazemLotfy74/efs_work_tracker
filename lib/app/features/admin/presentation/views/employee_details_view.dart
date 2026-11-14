import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/pickers/app_pickers.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/extensions/duration_format.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/feedback/app_dialog.dart';
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/manager/auth_cubit/auth_cubit.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';
import '../../domain/entities/employee_attendance_stats.dart';
import '../../domain/repositories/admin_repository.dart';
import '../manager/employee_details_cubit/employee_details_cubit.dart';
import '../widgets/admin_day_status.dart';
import '../widgets/admin_failure_text.dart';
import '../widgets/attendance_flag_chips.dart';
import '../../../../../core/constants/constants.dart';
import '../../../permissions/domain/entities/permission_set.dart';
import '../../../permissions/presentation/permissions_context.dart';

/// Admin only: one employee's profile, attendance statistics and days,
/// with the admin actions the database offers. Opening it changes nothing.
class EmployeeDetailsView extends StatelessWidget {
  const EmployeeDetailsView({super.key, required this.id, this.name});

  final String id;

  /// Shown as the title until the profile is loaded.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (context) =>
          EmployeeDetailsCubit(context.read<AdminRepository>(), id)..load(),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            spacing: 16,
            children: [
              customAppBar(
                context: context,
                title: name ?? l10n.employeeDetails,
                leading: CustomBackButton(),
              ),
              Expanded(
                child: BlocBuilder<EmployeeDetailsCubit, EmployeeDetailsState>(
                  builder: (context, state) => switch (state) {
                    EmployeeDetailsLoading() => AppLoadingView(
                      title: l10n.employeeDetails,
                      message: '',
                    ),
                    EmployeeDetailsError() => AppErrorView(
                      title: l10n.adminLoadFailed,
                      message: l10n.authNetworkError,
                      onRetry: context.read<EmployeeDetailsCubit>().load,
                    ),
                    EmployeeDetailsNotFound() => AppEmptyView(
                      title: l10n.adminNotFound,
                      message: '',
                      actionLabel: null,
                    ),
                    EmployeeDetailsLoaded() => _Details(state: state),
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

class _Details extends StatelessWidget {
  const _Details({required this.state});

  final EmployeeDetailsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = context.watch<ClockCubit>().state;
    final cubit = context.read<EmployeeDetailsCubit>();
    final days = state.visibleDays;
    final stats = EmployeeAttendanceStats.of(days, now);
    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        children: [
          _ProfileCard(state: state),
          const SizedBox(height: 12),
          _RangeFilter(range: state.range, onChanged: cubit.setRange),
          const SizedBox(height: 12),
          _StatsGrid(stats: stats),
          const SizedBox(height: 16),
          Text(l10n.adminAttendanceDays, style: context.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (days.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                l10n.adminNoDaysInRange,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          for (final day in days) ...[
            CustomContainer(
              key: Key('employeeDay-${day.id}'),
              borderWidth: 1,
              horizontalPadding: 14,
              verticalPadding: 12,
              onTap: () => context.push(AppRoutes.adminAttendanceDayOf(day.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Text(
                          (day.workDate ?? day.checkInTime).formatShortDate(
                            context,
                          ),
                          style: context.textTheme.labelLarge,
                        ),
                      ),
                      Flexible(
                        child: AdminDayStatus(session: day, now: now),
                      ),
                    ],
                  ),
                  AttendanceFlagChips(day: day, now: now),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state});

  final EmployeeDetailsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final employee = state.employee;
    final schedule = state.schedule;
    final createdAt = employee.createdAt;
    final me = context.select<AuthCubit, String?>(
      (cubit) => switch (cubit.state) {
        AuthSignedIn(:final user) => user.uID,
        _ => null,
      },
    );
    final can = context.permissions;
    // admin_set_employee_active: employee accounts only, never yourself.
    final canToggle = employee.role == UserRole.employee && employee.id != me;
    // admin_set_user_permissions: the same rule.
    final canManage =
        Constants.dynamicPermissions &&
        can.can(Permission.managePermissions) &&
        canToggle;
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 16,
      verticalPadding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          // An admin action (status, schedule, deletion) is being sent.
          if (state.busy)
            const LinearProgressIndicator(key: Key('employeeBusy')),
          Text(employee.fullName, style: context.textTheme.titleLarge),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              CustomStatusContainer(
                tone: StatusTone.success,
                text: employee.isAdmin ? l10n.roleAdmin : l10n.roleEmployee,
              ),
              CustomStatusContainer(
                key: const Key('accountStatus'),
                tone: employee.isActive ? StatusTone.success : StatusTone.error,
                text: employee.isActive ? l10n.adminActive : l10n.adminInactive,
              ),
              if (employee.isActive && employee.mustChangePassword)
                CustomStatusContainer(
                  tone: StatusTone.warning,
                  text: l10n.adminFirstSignInPending,
                ),
            ],
          ),
          const Divider(),
          InfoRow(label: l10n.employeeCode, value: employee.employeeCode),
          InfoRow(label: l10n.username, value: employee.username),
          if (employee.phone case final phone?)
            InfoRow(label: l10n.adminPhone, value: phone),
          InfoRow(
            label: l10n.workSchedule,
            value: schedule == null
                ? '--'
                : '${schedule.name} (${schedule.timezone})',
          ),
          if (createdAt != null)
            InfoRow(
              label: l10n.adminCreatedOn,
              value: createdAt.formatFullDate(context),
            ),
          const Divider(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canToggle && can.can(Permission.employeesEdit))
                OutlinedButton.icon(
                  key: const Key('toggleActive'),
                  onPressed: state.busy ? null : () => _toggleActive(context),
                  icon: Icon(
                    employee.isActive
                        ? Icons.person_off_outlined
                        : Icons.person_outline,
                  ),
                  label: Text(
                    employee.isActive
                        ? l10n.adminDeactivate
                        : l10n.adminActivate,
                  ),
                ),
              if (state.schedules.length > 1 &&
                  can.can(Permission.scheduleEdit))
                OutlinedButton.icon(
                  key: const Key('changeSchedule'),
                  onPressed: state.busy ? null : () => _changeSchedule(context),
                  icon: const Icon(Icons.schedule),
                  label: Text(l10n.adminChangeSchedule),
                ),
              // admin_edit_employee_profile: employee accounts only.
              if (can.isAdmin && employee.role == UserRole.employee)
                OutlinedButton.icon(
                  key: const Key('editEmployee'),
                  onPressed: state.busy ? null : () => _edit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.adminEditEmployee),
                ),
              if (can.can(Permission.auditView))
                OutlinedButton.icon(
                  key: const Key('auditHistory'),
                  onPressed: () => context.push(
                    AppRoutes.adminEmployeeAuditOf(employee.id),
                    extra: employee.fullName,
                  ),
                  icon: const Icon(Icons.history),
                  label: Text(l10n.adminAuditHistory),
                ),
              // Permanent deletion: admins only, employee accounts only,
              // never yourself. The server checks all three again.
              if (can.isAdmin && canToggle)
                OutlinedButton.icon(
                  key: const Key('deleteEmployee'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.error,
                    side: BorderSide(color: context.colors.error),
                  ),
                  onPressed: state.busy ? null : () => _delete(context),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(l10n.adminDeleteAccount),
                ),
              if (canManage)
                OutlinedButton.icon(
                  key: const Key('managePermissions'),
                  onPressed: () => context.push(
                    AppRoutes.adminEmployeePermissionsOf(employee.id),
                    extra: employee.fullName,
                  ),
                  icon: const Icon(Icons.key_outlined),
                  label: Text(l10n.permissionsTitle),
                ),
            ],
          ),
          if (!canToggle && employee.isAdmin)
            Text(
              l10n.adminAccountManagedByOperator,
              style: AppTextStyles.meta.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  /// Warns, then deletes. The page closes only after the server confirmed;
  /// on failure the employee stays and the reason is shown.
  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<EmployeeDetailsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteAccountDialog(name: state.employee.fullName),
    );
    if (confirmed != true) return;
    final failure = await cubit.delete();
    showAppSnackBar(
      messenger,
      failure?.message(l10n) ?? l10n.adminDeleteAccountDone,
      type: failure == null ? AppMessageType.success : AppMessageType.error,
    );
    // `true` tells the list behind to reload without this employee.
    if (failure == null) await navigator.maybePop(true);
  }

  /// Opens the edit form; reloads this page when the details were saved.
  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<EmployeeDetailsCubit>();
    final saved = await context.push<bool>(
      AppRoutes.adminEditEmployeeOf(state.employee.id),
    );
    if (saved == true) await cubit.load();
  }

  Future<void> _toggleActive(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<EmployeeDetailsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final employee = state.employee;
    final activate = !employee.isActive;
    final confirmed = await showAppConfirmationDialog(
      context,
      title: activate
          ? l10n.adminActivateTitle(employee.fullName)
          : l10n.adminDeactivateTitle(employee.fullName),
      message: activate
          ? l10n.adminActivateMessage
          : l10n.adminDeactivateMessage,
      confirmLabel: activate ? l10n.adminActivate : l10n.adminDeactivate,
      cancelLabel: l10n.correctionCancel,
      destructive: !activate,
    );
    if (!confirmed) return;
    final failure = await cubit.setActive(activate);
    showAppSnackBar(
      messenger,
      failure?.message(l10n) ?? l10n.adminStatusChanged,
      type: failure == null ? AppMessageType.success : AppMessageType.error,
    );
  }

  Future<void> _changeSchedule(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<EmployeeDetailsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.adminChangeSchedule),
        children: [
          for (final schedule in state.schedules)
            ListTile(
              title: Text(schedule.name),
              subtitle: Text(schedule.timezone),
              selected: schedule.id == state.employee.scheduleId,
              onTap: () => Navigator.of(dialogContext).pop(schedule.id),
            ),
        ],
      ),
    );
    if (picked == null || picked == state.employee.scheduleId) return;
    if (!context.mounted) return;
    final name = state.schedules.firstWhere((s) => s.id == picked).name;
    final confirmed = await showAppConfirmationDialog(
      context,
      title: l10n.adminScheduleChangeTitle(name),
      message: l10n.adminScheduleChangeMessage,
      confirmLabel: l10n.adminChangeSchedule,
      cancelLabel: l10n.correctionCancel,
    );
    if (!confirmed) return;
    final failure = await cubit.assignSchedule(picked);
    showAppSnackBar(
      messenger,
      failure?.message(l10n) ?? l10n.adminScheduleChanged,
      type: failure == null ? AppMessageType.success : AppMessageType.error,
    );
  }
}

/// The warning before a permanent deletion. Names the employee, and the
/// delete button works only after the admin ticks that it can't be undone,
/// so one stray tap never deletes an account. Pops `true` to go ahead.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.name});

  final String name;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: l10n.adminDeleteAccountTitle,
      message: l10n.adminDeleteAccountMessage,
      type: AppMessageType.error,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            l10n.adminDeleteAccountEmployee(widget.name),
            key: const Key('deleteEmployeeName'),
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium,
          ),
          CheckboxListTile(
            key: const Key('deleteAcknowledge'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: context.colors.error,
            value: _understood,
            onChanged: (value) => setState(() => _understood = value ?? false),
            title: Text(
              l10n.adminDeleteAccountAcknowledge,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          key: const Key('cancelDelete'),
          label: l10n.correctionCancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppDialogAction(
          key: const Key('confirmDelete'),
          label: l10n.adminDeleteAccountConfirm,
          primary: true,
          destructive: true,
          onPressed: _understood
              ? () => Navigator.of(context).pop(true)
              : null,
        ),
      ],
    );
  }
}

/// All / Today / Last 7 days / This month / custom range of work dates.
class _RangeFilter extends StatelessWidget {
  const _RangeFilter({required this.range, required this.onChanged});

  final WorkDateRange? range;
  final ValueChanged<WorkDateRange?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = context.read<ClockCubit>().state.toLocal();
    final today = WorkDateRange(now, now);
    final week = WorkDateRange(now.subtract(const Duration(days: 6)), now);
    final month = WorkDateRange(DateTime(now.year, now.month), now);
    final presets = <(String, WorkDateRange?)>[
      (l10n.adminRangeAll, null),
      (l10n.adminRangeToday, today),
      (l10n.adminRange7, week),
      (l10n.adminRangeMonth, month),
    ];
    final custom = range != null && !presets.any((p) => p.$2 == range);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (label, value) in presets)
          ChoiceChip(
            label: Text(label),
            selected: range == value,
            onSelected: (_) => onChanged(value),
          ),
        ChoiceChip(
          key: const Key('customRange'),
          avatar: const Icon(Icons.date_range, size: 18),
          label: Text(
            custom
                ? '${range!.from.formatShortDate(context)} – '
                      '${range!.to.formatShortDate(context)}'
                : l10n.adminRangeCustom,
          ),
          selected: custom,
          onSelected: (_) async {
            final picked = await showAppDateRangePicker(
              context,
              firstDate: DateTime(2020),
              lastDate: now,
              initialRange: range == null
                  ? null
                  : DateTimeRange(start: range!.from, end: range!.to),
            );
            if (picked != null) {
              onChanged(WorkDateRange(picked.start, picked.end));
            }
          },
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final EmployeeAttendanceStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (l10n.adminStatDays, '${stats.days}'),
      (l10n.adminStatWorked, stats.worked.formatHoursMinutes(context)),
      (l10n.observedOvertime, stats.overtime.formatHoursMinutes(context)),
      (l10n.adminStatLate, '${stats.late}'),
      (l10n.adminLeftEarly, '${stats.leftEarly}'),
      (l10n.adminStatMissing, '${stats.missingCheckOut}'),
      (l10n.adminStatReview, '${stats.needsAttention}'),
      (l10n.adminStatCorrected, '${stats.corrected}'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (label, value) in items)
              SizedBox(
                width: width,
                child: CustomContainer(
                  borderWidth: 1,
                  horizontalPadding: 12,
                  verticalPadding: 10,
                  containerColor: context.colors.surfaceContainerLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: context.textTheme.titleLarge),
                      Text(
                        label,
                        style: AppTextStyles.meta.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
