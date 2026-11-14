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
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/extensions/duration_format.dart';
import '../../../attendance_correction/domain/correction_rules.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../attendance_session/presentation/widgets/prepare/info_row.dart';
import '../../../home/presentation/widgets/custom_status_container.dart';
import '../manager/admin_dashboard_cubit/admin_dashboard_cubit.dart';
import '../../../permissions/domain/entities/permission_set.dart';
import '../../../permissions/presentation/permissions_context.dart';
import 'admin_day_status.dart';

class AdminDashboardViewBody extends StatefulWidget {
  const AdminDashboardViewBody({super.key, this.overview = true});

  /// Everyone's attendance today and the employee list; needs
  /// employees.view and attendance.view_all. Without them only the tools
  /// this account may use are shown.
  final bool overview;

  @override
  State<AdminDashboardViewBody> createState() => _AdminDashboardViewBodyState();
}

/// Which employees the list shows.
enum _Filter { all, checkedIn, notCheckedIn, needsReview }

class _AdminDashboardViewBodyState extends State<AdminDashboardViewBody> {
  String _query = '';
  _Filter _filter = _Filter.all;

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
        if (!widget.overview)
          const Expanded(child: SingleChildScrollView(child: AdminActions()))
        else
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
                AdminDashboardLoaded(
                  :final rows,
                  :final earlyDepartures,
                  :final stale,
                ) =>
                  _Loaded(
                    rows: rows,
                    earlyDepartures: earlyDepartures,
                    stale: stale,
                    query: _query,
                    onQuery: (query) => setState(() => _query = query),
                    filter: _filter,
                    onFilter: (filter) => setState(() => _filter = filter),
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
    required this.earlyDepartures,
    required this.stale,
    required this.query,
    required this.onQuery,
    required this.filter,
    required this.onFilter,
  });

  final List<EmployeeToday> rows;
  final List<EmployeeToday> earlyDepartures;
  final bool stale;
  final String query;
  final ValueChanged<String> onQuery;
  final _Filter filter;
  final ValueChanged<_Filter> onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = context.watch<ClockCubit>().state;
    final cubit = context.read<AdminDashboardCubit>();
    AttendanceDayStatus? status(EmployeeToday row) => row.today?.statusAt(now);
    bool shown(EmployeeToday row, _Filter filter) => switch (filter) {
      _Filter.all => true,
      _Filter.checkedIn => status(row) == AttendanceDayStatus.inProgress,
      _Filter.notCheckedIn => row.today == null && row.employee.isActive,
      _Filter.needsReview => status(row) == AttendanceDayStatus.needsReview,
    };
    int count(bool Function(EmployeeToday row) test) => rows.where(test).length;
    int countOf(_Filter filter) => count((row) => shown(row, filter));
    final visible = [
      for (final row in rows)
        if (shown(row, filter) && row.employee.matches(query)) row,
    ];

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        children: [
          _TodayCard(
            date: now.formatFullDate(context),
            stats: [
              (
                Icons.login_rounded,
                l10n.adminCheckedInNow,
                countOf(_Filter.checkedIn),
              ),
              (
                Icons.logout_rounded,
                l10n.checkedOut,
                count((r) => status(r) == AttendanceDayStatus.completed),
              ),
              (
                Icons.error_outline_rounded,
                l10n.needsReview,
                countOf(_Filter.needsReview),
              ),
              (
                Icons.directions_walk_rounded,
                l10n.adminLeftEarly,
                count((r) => r.today?.leftEarly ?? false),
              ),
              (
                Icons.schedule_rounded,
                l10n.notCheckedIn,
                countOf(_Filter.notCheckedIn),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminActions(onReturn: cubit.load),
          if (earlyDepartures.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionLabel(l10n.adminEarlyDepartures),
            _GroupCard(
              children: [
                for (final day in earlyDepartures)
                  _EarlyDepartureTile(day: day),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _SectionLabel(l10n.adminEmployees),
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                for (final (value, label) in [
                  (_Filter.all, l10n.adminRangeAll),
                  (_Filter.checkedIn, l10n.adminCheckedInNow),
                  (_Filter.notCheckedIn, l10n.notCheckedIn),
                  (_Filter.needsReview, l10n.needsReview),
                ])
                  _FilterChip(
                    key: Key('adminFilter-${value.name}'),
                    // "All" needs no number; the others say how many.
                    label: value == _Filter.all
                        ? label
                        : '$label ${countOf(value)}',
                    selected: filter == value,
                    onTap: () => onFilter(value),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
            )
          else
            _GroupCard(
              children: [
                for (final row in visible) _EmployeeTile(row: row, now: now),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// The dark summary card: today's date and how many employees are in each
/// state, two to a line.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.date, required this.stats});

  final String date;
  final List<(IconData, String, int)> stats;

  @override
  Widget build(BuildContext context) {
    final brand = context.appColors;
    const gap = 12.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand.brandSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.adminToday,
            style: context.textTheme.titleMedium?.copyWith(
              color: brand.onBrandSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: context.textTheme.bodySmall?.copyWith(
              color: brand.onBrandSurfaceMuted,
            ),
          ),
          Divider(height: 24, color: brand.brandSurfaceBadge),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: gap,
              runSpacing: 14,
              children: [
                for (final (icon, label, value) in stats)
                  SizedBox(
                    width: (constraints.maxWidth - gap) / 2,
                    child: Row(
                      spacing: 10,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: brand.brandSurfaceBadge,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 20,
                            color: brand.onBrandSurface,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: AppTextStyles.meta.copyWith(
                                  color: brand.onBrandSurfaceMuted,
                                ),
                              ),
                              Text(
                                '$value',
                                style: context.textTheme.titleMedium?.copyWith(
                                  color: brand.onBrandSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The small capital heading above a card ("PREFERENCES" in the design).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text.toUpperCase(),
        style: context
            .tracked(AppTextStyles.overline)
            .copyWith(color: context.colors.onSurfaceVariant),
      ),
    ),
  );
}

/// One rounded white card holding several rows, with a line between them.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colors.outlineVariant,
              ),
            child,
          ],
        ],
      ),
    );
  }
}

/// The rounded square that holds a row's icon or initials.
class _Tile extends StatelessWidget {
  const _Tile({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(13),
    ),
    child: child,
  );
}

/// A pill that picks which employees are listed; the chosen one is dark.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? brand.brandSurface : colors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? brand.brandSurface : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: selected ? brand.onBrandSurface : colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The admin tools this account may use (see `AppRouter._allowed` for the
/// same rules). [onReturn] runs after a tool that changes the overview.
class AdminActions extends StatelessWidget {
  const AdminActions({super.key, this.onReturn});

  final Future<void> Function()? onReturn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final can = context.permissions;
    Future<void> open(String route) async {
      await context.push(route);
      await onReturn?.call();
    }

    final actions = [
      if (can.isAdmin)
        _Action(
          key: const Key('adminAddEmployee'),
          icon: Icons.person_add_alt_1_outlined,
          label: l10n.adminAddEmployee,
          onTap: () => open(AppRoutes.adminAddEmployee),
        ),
      if (can.can(Permission.correctionsView))
        _Action(
          key: const Key('adminCorrections'),
          icon: Icons.fact_check_outlined,
          label: l10n.adminCorrections,
          onTap: () => open(AppRoutes.adminCorrections),
        ),
      if (can.can(Permission.cashViewAll))
        _Action(
          key: const Key('adminRequests'),
          icon: Icons.request_page_outlined,
          label: l10n.adminRequests,
          onTap: () => context.push(AppRoutes.adminRequests),
        ),
      if (can.can(Permission.reportsView))
        _Action(
          key: const Key('adminReports'),
          icon: Icons.table_view_outlined,
          label: l10n.hrReports,
          onTap: () => context.push(AppRoutes.adminReports),
        ),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _SectionLabel(l10n.adminTools),
        _GroupCard(children: actions),
      ],
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
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            _Tile(
              color: colors.surfaceContainerLow,
              child: Icon(icon, size: 22, color: colors.onSurface),
            ),
            Expanded(child: Text(label, style: context.textTheme.labelLarge)),
            // Flips by itself in Arabic.
            Icon(Icons.chevron_right, color: colors.onSurface),
          ],
        ),
      ),
    );
  }
}

/// First letters of the first two names, for the avatar square.
String _initials(String fullName) {
  final words = fullName.trim().split(RegExp(r'\s+'));
  return [
    for (final word in words.take(2))
      if (word.isNotEmpty) word.characters.first.toUpperCase(),
  ].join();
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.row, required this.now});

  final EmployeeToday row;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final brand = context.appColors;
    final employee = row.employee;
    final today = row.today;
    final notes = [
      employee.employeeCode,
      if (!employee.isActive) l10n.adminInactive,
      if (employee.isActive && employee.mustChangePassword)
        l10n.adminFirstSignInPending,
    ].join(' · ');
    return InkWell(
      // The employee page pops `true` after a permanent deletion: reload so
      // the list no longer shows the account.
      onTap: () async {
        final cubit = context.read<AdminDashboardCubit>();
        final changed = await context.push<bool>(
          AppRoutes.adminEmployeeOf(employee.id),
          extra: employee.fullName,
        );
        if (changed == true) await cubit.load();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            _Tile(
              color: employee.isActive
                  ? brand.brandSurface
                  : colors.surfaceContainerLow,
              child: ExcludeSemantics(
                child: Text(
                  _initials(employee.fullName),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: employee.isActive
                        ? brand.onBrandSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
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
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: today == null
                  ? Text(
                      l10n.notCheckedIn,
                      textAlign: TextAlign.end,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    )
                  : AdminDayStatus(session: today, now: now),
            ),
          ],
        ),
      ),
    );
  }
}

/// One day on which an employee checked out before their shift ended:
/// who, the date, the shift, the actual check-out and the shift end, in
/// the day's own timezone. Opens the employee's history.
class _EarlyDepartureTile extends StatelessWidget {
  const _EarlyDepartureTile({required this.day});

  final EmployeeToday day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = day.today!;
    final employee = day.employee;
    String time(DateTime instant) => CorrectionRules.wallClock(
      session.timezone,
      instant,
    ).formatTime(context);
    final date = session.workDate ?? session.checkInTime;
    return InkWell(
      key: Key('earlyDeparture-${session.id}'),
      // The employee page pops `true` after a permanent deletion: reload so
      // the list no longer shows the account.
      onTap: () async {
        final cubit = context.read<AdminDashboardCubit>();
        final changed = await context.push<bool>(
          AppRoutes.adminEmployeeOf(employee.id),
          extra: employee.fullName,
        );
        if (changed == true) await cubit.load();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            _Tile(
              color: context.appColors.warningContainer,
              child: Icon(
                Icons.warning_amber_rounded,
                size: 22,
                color: context.appColors.warning,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Text(
                          employee.fullName,
                          style: context.textTheme.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: CustomStatusContainer(
                          tone: StatusTone.warning,
                          text: l10n.adminLeftEarlyBy(
                            session.leftEarlyBy.formatHoursMinutes(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    date.formatFullDate(context),
                    style: AppTextStyles.meta.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  InfoRow(
                    label: l10n.workSchedule,
                    value:
                        '${time(session.shift.startsAt ?? session.checkInTime)}'
                        ' – ${time(session.scheduledEnd)}',
                  ),
                  InfoRow(
                    label: l10n.checkedOut,
                    value: time(session.checkOutTime!),
                  ),
                  InfoRow(
                    label: l10n.adminShiftEnd,
                    value: time(session.scheduledEnd),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
