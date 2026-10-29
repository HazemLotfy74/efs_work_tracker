import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../manager/admin_dashboard_cubit/admin_dashboard_cubit.dart';
import 'admin_day_status.dart';

class AdminDashboardViewBody extends StatefulWidget {
  const AdminDashboardViewBody({super.key});

  @override
  State<AdminDashboardViewBody> createState() => _AdminDashboardViewBodyState();
}

class _AdminDashboardViewBodyState extends State<AdminDashboardViewBody> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      spacing: 16,
      children: [
        customAppBar(
          context: context,
          title: l10n.adminDashboard,
          leading: CustomBackButton(),
        ),
        Expanded(
          child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
            builder: (context, state) => switch (state) {
              AdminDashboardLoading() => AppLoadingView(
                title: l10n.adminDashboard,
                message: '',
              ),
              AdminDashboardError() => AppErrorView(
                title: l10n.adminLoadFailed,
                message: l10n.authNetworkError,
                onRetry: context.read<AdminDashboardCubit>().load,
              ),
              AdminDashboardLoaded(:final rows, :final stale) => _Loaded(
                rows: rows,
                stale: stale,
                query: _query,
                onQuery: (query) => setState(() => _query = query),
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.rows,
    required this.stale,
    required this.query,
    required this.onQuery,
  });

  final List<EmployeeToday> rows;
  final bool stale;
  final String query;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = context.watch<ClockCubit>().state;
    final cubit = context.read<AdminDashboardCubit>();
    int count(bool Function(EmployeeToday row) test) => rows.where(test).length;
    AttendanceDayStatus? status(EmployeeToday row) => row.today?.statusAt(now);
    final visible = rows.where((row) => row.employee.matches(query)).toList();

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Count(
                label: l10n.adminCheckedInNow,
                value: count(
                  (r) => status(r) == AttendanceDayStatus.inProgress,
                ),
              ),
              _Count(
                label: l10n.checkedOut,
                value: count((r) => status(r) == AttendanceDayStatus.completed),
              ),
              _Count(
                label: l10n.needsReview,
                value: count(
                  (r) => status(r) == AttendanceDayStatus.needsReview,
                ),
              ),
              _Count(
                label: l10n.notCheckedIn,
                value: count((r) => r.today == null && r.employee.isActive),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Action(
            key: const Key('adminAddEmployee'),
            icon: Icons.person_add_alt_1_outlined,
            label: l10n.adminAddEmployee,
            onTap: () async {
              await context.push(AppRoutes.adminAddEmployee);
              await cubit.load();
            },
          ),
          const SizedBox(height: 10),
          _Action(
            key: const Key('adminCorrections'),
            icon: Icons.fact_check_outlined,
            label: l10n.adminCorrections,
            onTap: () async {
              await context.push(AppRoutes.adminCorrections);
              await cubit.load();
            },
          ),
          const SizedBox(height: 10),
          _Action(
            key: const Key('adminRequests'),
            icon: Icons.request_page_outlined,
            label: l10n.adminRequests,
            onTap: () => context.push(AppRoutes.adminRequests),
          ),
          const SizedBox(height: 16),
          Text(l10n.adminToday, style: context.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (stale)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l10n.adminStaleData,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ),
          TextField(
            key: const Key('adminSearch'),
            onChanged: onQuery,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.adminSearchHint,
            ),
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                l10n.adminNoEmployees,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          for (final row in visible) ...[
            _EmployeeTile(row: row, now: now),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140),
      child: CustomContainer(
        borderWidth: 1,
        horizontalPadding: 14,
        verticalPadding: 12,
        containerColor: context.colors.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value', style: context.textTheme.headlineSmall),
            Text(
              label,
              style: AppTextStyles.meta.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 16,
      verticalPadding: 14,
      onTap: onTap,
      child: Row(
        spacing: 10,
        children: [
          Icon(icon, color: context.colors.primary),
          Expanded(child: Text(label, style: context.textTheme.labelLarge)),
          Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.row, required this.now});

  final EmployeeToday row;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final employee = row.employee;
    final today = row.today;
    final notes = [
      employee.employeeCode,
      if (!employee.isActive) l10n.adminInactive,
      if (employee.isActive && employee.mustChangePassword)
        l10n.adminFirstSignInPending,
    ].join(' · ');
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 14,
      verticalPadding: 12,
      onTap: () => context.push(
        AppRoutes.adminEmployeeOf(employee.id),
        extra: employee.fullName,
      ),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  employee.fullName,
                  style: context.textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  notes,
                  style: AppTextStyles.meta.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: today == null
                ? Text(
                    l10n.notCheckedIn,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                : AdminDayStatus(session: today, now: now),
          ),
        ],
      ),
    );
  }
}
