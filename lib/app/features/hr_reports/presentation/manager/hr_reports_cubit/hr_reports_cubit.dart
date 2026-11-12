import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/admin_errors.dart';
import '../../../data/hr_workbook.dart';
import '../../../domain/entities/hr_report.dart';
import '../../../domain/hr_report_builder.dart';
import '../../../domain/repositories/hr_report_repository.dart';

part 'hr_reports_state.dart';

/// Loads a month's report for the preview and exports it as an Excel
/// workbook. The workbook is built on a background isolate so the screen
/// keeps responding.
class HrReportsCubit extends Cubit<HrReportsState> {
  HrReportsCubit(
    this._repository,
    this._builder, {
    required this.generatedBy,
    DateTime Function() now = DateTime.now,
    Future<Uint8List> Function(HrReport report)? encode,
  }) : _now = now,
       _encode = encode ?? _encodeInBackground,
       super(HrReportsLoading(HrReportPeriod.of(now())));

  final HrReportRepository _repository;
  final HrReportBuilder _builder;
  final DateTime Function() _now;
  final Future<Uint8List> Function(HrReport report) _encode;

  /// The admin's name, printed on the information sheet.
  final String generatedBy;

  /// Only the newest load may emit.
  int _loadId = 0;

  HrReportPeriod get current => HrReportPeriod.of(_now());

  Future<void> load([HrReportPeriod? period]) async {
    final target = period ?? state.period;
    if (target.first.isAfter(current.first)) return; // no future months
    final loadId = ++_loadId;
    emit(HrReportsLoading(target));
    try {
      final input = await _repository.load(target, generatedBy: generatedBy);
      final report = _builder.build(input);
      if (isClosed || loadId != _loadId) return;
      emit(HrReportsLoaded(target, report));
    } on AdminFailure catch (failure) {
      if (isClosed || loadId != _loadId) return;
      emit(HrReportsError(target, failure));
    }
  }

  Future<void> previous() => load(state.period.previous);

  Future<void> next() async {
    if (state.period == current) return;
    await load(state.period.next);
  }

  /// Builds the workbook and opens the share sheet. One export at a time.
  Future<void> export() async {
    final loaded = state;
    if (loaded is! HrReportsLoaded || loaded.exporting) return;
    emit(loaded.copyWith(exporting: true, exportFailed: false));
    try {
      final bytes = await _encode(loaded.report);
      await _repository.share(bytes, loaded.period.fileName);
      if (isClosed) return;
      emit(loaded.copyWith(exporting: false, exported: true));
    } on Exception {
      if (isClosed) return;
      emit(loaded.copyWith(exporting: false, exportFailed: true));
    }
  }

  static Future<Uint8List> _encodeInBackground(HrReport report) =>
      Isolate.run(() => HrWorkbook.encode(report));
}
