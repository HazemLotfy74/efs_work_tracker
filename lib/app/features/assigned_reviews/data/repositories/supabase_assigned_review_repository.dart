import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/admin_errors.dart';
import '../../../../../core/services/database_services.dart';
import '../../../admin/data/repositories/supabase_admin_repository.dart';
import '../../../attendance_correction/data/models/correction_request_model.dart';
import '../../../attendance_correction/domain/entities/correction_request_entity.dart';
import '../../../cash_request/data/models/expense_advance_request_model.dart';
import '../../../cash_request/domain/entities/expense_advance_request_entity.dart';
import '../../domain/repositories/assigned_review_repository.dart';

/// [AssignedReviewRepository] on the live database, unchanged: reads
/// through the `*_read_assigned_reviewer` policies and decides through the
/// `review_assigned_*` functions, which check the permission, the
/// assignment and the pending status themselves.
class SupabaseAssignedReviewRepository implements AssignedReviewRepository {
  SupabaseAssignedReviewRepository({
    required this._databaseServices,
    required this._currentUserId,
    this.timeout = const Duration(seconds: 20),
  });

  final DatabaseServices _databaseServices;
  final String? Function() _currentUserId;
  final Duration timeout;

  // The day is embedded for its date and timezone; it is `null` when the
  // reviewer may not read it.
  static const _correctionColumns =
      'id, employee_id, attendance_id, proposed_checkin, proposed_checkout, '
      'reason, status, review_note, reviewed_at, created_at, '
      'assigned_reviewer_id, '
      'attendance:attendance_records(work_date, timezone, actual_checkin)';

  @override
  Future<List<ExpenseAdvanceRequestEntity>> getCash() async {
    final rows = await _read(
      'expense_advance_requests',
      ExpenseAdvanceRequestModel.columns,
    );
    return _parse(rows, ExpenseAdvanceRequestModel.fromJson);
  }

  @override
  Future<List<CorrectionRequestEntity>> getCorrections() async {
    final rows = await _read(
      'attendance_correction_requests',
      _correctionColumns,
    );
    return _parse(rows, CorrectionRequestModel.fromJson);
  }

  @override
  Future<void> reviewCash(String id, {required bool approve, String? note}) =>
      _review('review_assigned_expense_advance', id, approve, note);

  @override
  Future<void> reviewCorrection(
    String id, {
    required bool approve,
    String? note,
  }) => _review('review_assigned_attendance_correction', id, approve, note);

  Future<Object?> _read(String table, String columns) {
    final userId = _currentUserId() ?? (throw AdminFailure.notAllowed);
    return _guard(
      table,
      () => _databaseServices.getData(
        path: table,
        column: columns,
        query: {'assigned_reviewer_id': userId, 'status': 'pending'},
        orderBy: 'created_at',
      ),
    );
  }

  Future<void> _review(String function, String id, bool approve, String? note) {
    if (_currentUserId() == null) throw AdminFailure.notAllowed;
    final text = note?.trim();
    return _guard(
      function,
      () => _databaseServices.rpc(
        function: function,
        params: {
          'p_request_id': id,
          'p_approve': approve,
          'p_note': text == null || text.isEmpty ? null : text,
        },
      ),
    );
  }

  Future<Object?> _guard(
    String name,
    Future<dynamic> Function() request,
  ) async {
    try {
      return await request().timeout(timeout);
    } on PostgrestException catch (e) {
      log('$name failed: code ${e.code}');
      throw SupabaseAdminRepository.failureFor(e.code, e.message);
    } on Exception catch (e) {
      log('$name failed: ${e.runtimeType}');
      throw AdminFailure.network;
    }
  }

  static List<T> _parse<T>(
    Object? rows,
    T Function(Map<String, dynamic> json) parse,
  ) {
    try {
      return [
        for (final row in (rows as List).cast<Map>())
          parse(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      log('Unreadable assigned requests: ${e.runtimeType}');
      throw AdminFailure.unknown;
    }
  }
}
