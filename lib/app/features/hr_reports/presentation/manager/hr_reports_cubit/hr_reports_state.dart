part of 'hr_reports_cubit.dart';

sealed class HrReportsState {
  const HrReportsState(this.period);

  final HrReportPeriod period;
}

final class HrReportsLoading extends HrReportsState {
  const HrReportsLoading(super.period);
}

final class HrReportsError extends HrReportsState {
  const HrReportsError(super.period, this.failure);

  final AdminFailure failure;
}

final class HrReportsLoaded extends HrReportsState {
  const HrReportsLoaded(
    super.period,
    this.report, {
    this.exporting = false,
    this.exported = false,
    this.exportFailed = false,
  });

  final HrReport report;

  /// The workbook is being built or shared.
  final bool exporting;

  /// The share sheet was opened for this report.
  final bool exported;
  final bool exportFailed;

  HrReportsLoaded copyWith({
    bool? exporting,
    bool? exported,
    bool? exportFailed,
  }) => HrReportsLoaded(
    period,
    report,
    exporting: exporting ?? this.exporting,
    exported: exported ?? this.exported,
    exportFailed: exportFailed ?? this.exportFailed,
  );
}
