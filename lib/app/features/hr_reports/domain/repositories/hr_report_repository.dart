import 'dart:typed_data';

import '../entities/hr_report.dart';

/// Reads what an HR report needs. Only administrators can: the tables'
/// RLS policies return other employees' rows to admins only, so a
/// non-admin gets their own data at most (and never sees this screen).
///
/// Every method throws an `AdminFailure` (core/errors/admin_errors.dart).
abstract interface class HrReportRepository {
  /// Employees, schedules, attendance days and corrections of [period].
  Future<HrReportInput> load(
    HrReportPeriod period, {
    required String generatedBy,
    String? employeeId,
  });

  /// Saves [bytes] as [fileName] in a temporary folder and opens the share
  /// sheet. The file is deleted afterwards.
  Future<void> share(Uint8List bytes, String fileName);
}
