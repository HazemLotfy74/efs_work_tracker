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
import '../../../../../core/widgets/feedback/app_message_type.dart';
import '../../../../../core/widgets/feedback/app_snack_bar.dart';
import '../../../../../core/widgets/states/app_error_view.dart';
import '../../../../../core/widgets/states/app_loading_view.dart';
import '../../../admin/presentation/widgets/admin_failure_text.dart';
import '../../../auth/presentation/manager/auth_cubit/auth_cubit.dart';
import '../../data/hr_workbook.dart';
import '../../data/repositories/supabase_hr_report_repository.dart';
import '../../domain/entities/hr_report.dart';
import '../../domain/hr_report_builder.dart';
import '../../domain/repositories/hr_report_repository.dart';
import '../manager/hr_reports_cubit/hr_reports_cubit.dart';
import '../../../permissions/domain/entities/permission_set.dart';
import '../../../permissions/presentation/permissions_context.dart';

/// Admin only: a month's attendance figures from the live records, and the
/// HR workbook (Excel) for payroll preparation, shared from the phone.
class HrReportsView extends StatelessWidget {
  const HrReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final generatedBy = switch (context.read<AuthCubit>().state) {
      AuthSignedIn(:final user) => user.fullName,
      _ => '',
    };
    return BlocProvider(
      create: (context) => HrReportsCubit(
        context.read<HrReportRepository>(),
        const HrReportBuilder(localWallTime),
        generatedBy: generatedBy,
      )..load(),
      child: const _HrReportsBody(),
    );
  }
}

class _HrReportsBody extends StatelessWidget {
  const _HrReportsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<HrReportsCubit>();
    return BlocListener<HrReportsCubit, HrReportsState>(
      listenWhen: (previous, current) =>
          current is HrReportsLoaded &&
          current.exportFailed &&
          !(previous is HrReportsLoaded && previous.exportFailed),
      listener: (context, state) => showAppSnackBar(
        ScaffoldMessenger.of(context),
        l10n.hrReportsExportFailed,
        type: AppMessageType.error,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              spacing: 16,
              children: [
                customAppBar(
                  context: context,
                  title: l10n.hrReports,
                  leading: CustomBackButton(),
                ),
                BlocBuilder<HrReportsCubit, HrReportsState>(
                  buildWhen: (a, b) => a.period != b.period,
                  builder: (context, state) => _MonthPicker(
                    period: state.period,
                    canGoNext: state.period != cubit.current,
                  ),
                ),
                Expanded(
                  child: BlocBuilder<HrReportsCubit, HrReportsState>(
                    builder: (context, state) => switch (state) {
                      HrReportsLoading() => AppLoadingView(
                        title: l10n.hrReports,
                        message: '',
                      ),
                      HrReportsError(:final failure) => AppErrorView(
                        title: l10n.adminLoadFailed,
                        message: failure.message(l10n),
                        onRetry: cubit.load,
                      ),
                      HrReportsLoaded() => _Preview(state: state),
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

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.period, required this.canGoNext});

  final HrReportPeriod period;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<HrReportsCubit>();
    // Arrows follow the reading direction: "previous" points to the start.
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 4,
      verticalPadding: 4,
      child: Row(
        children: [
          IconButton(
            key: const Key('hrPreviousMonth'),
            tooltip: l10n.hrReportsPreviousMonth,
            onPressed: cubit.previous,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  period.first.formatMonthYear(context),
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium,
                ),
                Text(
                  l10n.hrReportsSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.meta.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('hrNextMonth'),
            tooltip: l10n.hrReportsNextMonth,
            onPressed: canGoNext ? cubit.next : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final HrReportsLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final report = state.report;
    final overtime = HrWorkbook.hoursOf(report.overtime);
    final stats = [
      (l10n.hrReportsEmployees, '${report.employeeCount}', false),
      (l10n.hrReportsAttendanceDays, '${report.attendanceDays}', false),
      (l10n.hrReportsAbsences, '${report.absenceDays}', report.absenceDays > 0),
      (l10n.hrReportsLateDays, '${report.lateDays}', false),
      (
        l10n.hrReportsOvertime,
        // 3.5 h, 12 h: up to two decimals, no trailing zeros.
        l10n.hrReportsHours(
          overtime.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
        ),
        false,
      ),
      (
        l10n.hrReportsPendingCorrections,
        '${report.pendingCorrections}',
        report.pendingCorrections > 0,
      ),
      (
        l10n.hrReportsNeedsReview,
        '${report.pendingReviews}',
        report.pendingReviews > 0,
      ),
    ];
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              if (report.employeeCount == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.hrReportsNoEmployees,
                    style: context.textTheme.bodyLarge,
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Two cards a row on phones, three on wider screens.
                  final columns = constraints.maxWidth >= 600 ? 3 : 2;
                  final width =
                      (constraints.maxWidth - 10 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final (label, value, attention) in stats)
                        SizedBox(
                          width: width,
                          child: _Stat(
                            label: label,
                            value: value,
                            attention: attention,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: context.colors.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Text(
                      l10n.hrReportsSource,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppPrimaryButton(
          key: const Key('hrGenerate'),
          // reports.export; the figures alone need reports.view.
          onPressed:
              state.exporting ||
                  report.employeeCount == 0 ||
                  !context.permissions.can(Permission.reportsExport)
              ? null
              : context.read<HrReportsCubit>().export,
          child: state.exporting
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: [
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    Flexible(child: Text(l10n.hrReportsGenerating)),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    const Icon(Icons.table_view_outlined),
                    Flexible(child: Text(l10n.hrReportsGenerate)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.attention,
  });

  final String label;
  final String value;

  /// Something HR should look at: shown in the warning color.
  final bool attention;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      borderWidth: 1,
      horizontalPadding: 14,
      verticalPadding: 12,
      containerColor: attention
          ? context.appColors.warningContainer
          : context.colors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              color: attention ? context.appColors.warning : null,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.meta.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
