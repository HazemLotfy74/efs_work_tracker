import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/pickers/app_pickers.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/manager/clock_cubit.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/states/app_empty_view.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../attendance_correction/domain/correction_rules.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../../attendance_session/presentation/widgets/attendance_day_status_text.dart';
import '../../domain/attendance_history_summary.dart';
import '../manager/attendance_history_cubit/attendance_history_cubit.dart';
import 'attendance_history_tile.dart';
import 'history_summary_cards.dart';

/// Owns search/filter controls; repository loading stays in the Cubit.
class HistoryViewBody extends StatefulWidget {
  const HistoryViewBody({super.key});
  @override
  State<HistoryViewBody> createState() => _HistoryViewBodyState();
}

class _HistoryViewBodyState extends State<HistoryViewBody> {
  final _search = TextEditingController();
  AttendanceHistoryFilter _filter = AttendanceHistoryFilter.all;
  DateTime? _day;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _filterLabel(AttendanceHistoryFilter filter) => switch (filter) {
    AttendanceHistoryFilter.all => context.l10n.historyAll,
    AttendanceHistoryFilter.late => context.l10n.historyLate,
    AttendanceHistoryFilter.overtime => context.l10n.observedOvertime,
    AttendanceHistoryFilter.needsReview => context.l10n.needsReview,
  };

  Future<void> _chooseDate() async {
    final cubit = context.read<AttendanceHistoryCubit>();
    // No attendance can exist in the future or before the app existed.
    final today = DateTime.now();
    final date = await showAppDatePicker(
      context,
      initialDate: _day ?? cubit.month,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (date == null || !mounted) return;
    setState(() => _day = date);
    await cubit.selectMonth(date);
  }

  void _changeMonth(int delta) {
    final cubit = context.read<AttendanceHistoryCubit>();
    setState(() => _day = null);
    cubit.selectMonth(DateTime(cubit.month.year, cubit.month.month + delta));
  }

  bool _matches(AttendanceSessionEntity session, DateTime now) {
    if (!_filter.matches(session, now)) return false;
    final date =
        session.workDate ??
        CorrectionRules.wallClock(session.timezone, session.checkInTime);
    if (_day != null && !DateUtils.isSameDay(_day, date)) return false;
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
      date.formatFullDate(context),
      DateFormat('yyyy-MM-dd').format(date),
      DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
          .format(date),
      session.statusAt(now).label(context.l10n),
      session.lateMinutes > 0 ? context.l10n.historyLate : context.l10n.onTime,
    ].join(' ').toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final now = context.watch<ClockCubit>().state;
    final l10n = context.l10n;
    return BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
      builder: (context, state) {
        final cubit = context.read<AttendanceHistoryCubit>();
        final sessions = state is AttendanceHistoryLoaded
            ? state.sessions
            : <AttendanceSessionEntity>[];
        final visible = sessions.where((day) => _matches(day, now)).toList();
        return LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth < 360 ? 12.0 : 18.0;
            Widget bounded(Widget child) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: child,
              ),
            );
            return RefreshIndicator(
              onRefresh: cubit.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(padding, 18, padding, 0),
                    sliver: SliverToBoxAdapter(
                      child: bounded(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 48),
                                Expanded(
                                  child: Text(
                                    l10n.historyTitle,
                                    textAlign: TextAlign.center,
                                    style: context.textTheme.titleMedium,
                                  ),
                                ),
                                PopupMenuButton<AttendanceHistoryFilter>(
                                  tooltip: l10n.historyFilters,
                                  icon: const Icon(Icons.filter_list_rounded),
                                  initialValue: _filter,
                                  onSelected: (value) =>
                                      setState(() => _filter = value),
                                  itemBuilder: (_) => [
                                    for (final filter
                                        in AttendanceHistoryFilter.values)
                                      CheckedPopupMenuItem(
                                        value: filter,
                                        checked: filter == _filter,
                                        child: Text(_filterLabel(filter)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _HistoryIconButton(
                                  tooltip: l10n.historyPreviousMonth,
                                  icon: Icons.chevron_left,
                                  onPressed: () => _changeMonth(-1),
                                ),
                                Expanded(
                                  child: Text(
                                    DateFormat.yMMMM(
                                      Localizations.localeOf(context)
                                          .toLanguageTag(),
                                    ).format(cubit.month),
                                    textAlign: TextAlign.center,
                                    style: context.textTheme.titleSmall,
                                  ),
                                ),
                                _HistoryIconButton(
                                  tooltip: l10n.historyNextMonth,
                                  icon: Icons.chevron_right,
                                  onPressed: () => _changeMonth(1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (state is AttendanceHistoryLoaded) ...[
                              HistorySummaryCards(
                                summary: AttendanceHistorySummary(sessions),
                              ),
                              const SizedBox(height: 20),
                              if (state.stale) ...[
                                Text(
                                  l10n.historyStale,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.appColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _search,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      hintText: l10n.historySearch,
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: _search.text.isEmpty
                                          ? null
                                          : IconButton(
                                              tooltip: MaterialLocalizations.of(
                                                context,
                                              ).deleteButtonTooltip,
                                              onPressed: () =>
                                                  setState(_search.clear),
                                              icon: const Icon(Icons.close),
                                            ),
                                      filled: true,
                                      fillColor: context.colors.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: context.colors.outlineVariant,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: context.colors.outlineVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _HistoryIconButton(
                                  tooltip: l10n.historyChooseDate,
                                  icon: Icons.calendar_month_outlined,
                                  onPressed: _chooseDate,
                                ),
                              ],
                            ),
                            if (_day != null)
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: InputChip(
                                  label: Text(_day!.formatShortDate(context)),
                                  onDeleted: () => setState(() => _day = null),
                                ),
                              ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final filter
                                    in AttendanceHistoryFilter.values)
                                  ChoiceChip(
                                    label: Text(_filterLabel(filter)),
                                    selected: _filter == filter,
                                    showCheckmark: false,
                                    selectedColor:
                                        context.appColors.brandSurface,
                                    backgroundColor: context.colors.surface,
                                    labelStyle: context.textTheme.labelMedium
                                        ?.copyWith(
                                          color: _filter == filter
                                              ? context.appColors.onBrandSurface
                                              : context.colors.onSurfaceVariant,
                                        ),
                                    shape: const StadiumBorder(),
                                    onSelected: (_) =>
                                        setState(() => _filter = filter),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            if (state is AttendanceHistoryLoaded) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.historyRecent,
                                      style: context.textTheme.titleSmall,
                                    ),
                                  ),
                                  Text(
                                    l10n.historyRecords(visible.length),
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              context.colors.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state is AttendanceHistoryLoaded && visible.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(padding, 0, padding, 24),
                      sliver: SliverList.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) => bounded(
                          AttendanceHistoryTile(
                            session: visible[index],
                            first: index == 0,
                            last: index == visible.length - 1,
                          ),
                        ),
                      ),
                    ),
                  if (state is! AttendanceHistoryLoaded || visible.isEmpty)
                    SliverToBoxAdapter(
                      child: bounded(
                        SizedBox(
                          height:
                              400 + MediaQuery.textScalerOf(context).scale(100),
                          child: switch (state) {
                            AttendanceHistoryLoading() => AppLoadingView(
                              title: l10n.history,
                              message: '',
                            ),
                            AttendanceHistoryError() => AppErrorView(
                              title: l10n.historyLoadFailed,
                              message: l10n.authNetworkError,
                              onRetry: cubit.load,
                            ),
                            _ => AppEmptyView(
                              title: sessions.isEmpty
                                  ? l10n.historyEmptyTitle
                                  : l10n.historyNoMatches,
                              message: sessions.isEmpty
                                  ? l10n.historyEmptyMessage
                                  : l10n.historyNoMatchesMessage,
                              actionLabel: null,
                            ),
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HistoryIconButton extends StatelessWidget {
  const _HistoryIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => CustomContainer(
    borderWidth: 1,
    borderRadius: 14,
    horizontalPadding: 0,
    verticalPadding: 0,
    child: IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon)),
  );
}
