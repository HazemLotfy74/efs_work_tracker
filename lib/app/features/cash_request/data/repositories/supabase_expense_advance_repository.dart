import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/enums/request_status.dart';
import '../../../../../core/errors/request_errors.dart';
import '../../../../../core/services/database_services.dart';
import '../../domain/entities/expense_advance_request_entity.dart';
import '../../domain/repositories/expense_advance_repository.dart';
import '../models/expense_advance_request_model.dart';

/// Cash advance requests on the existing database, unchanged:
/// - reads `expense_advance_requests` through its RLS policy, always
///   filtered to the signed-in employee (an administrator's policy shows
///   everyone's);
/// - writes only through the existing function `request_expense_advance`,
///   which takes the employee from the session and always saves `pending`.
///
/// The database accepts the same request twice, so retries are made safe
/// here: before a draft is first sent, the ids of the employee's pending
/// requests with the same content are noted. After a send whose answer was
/// lost, a new pending request with that content is that send's result.
class SupabaseExpenseAdvanceRepository implements ExpenseAdvanceRepository {
  SupabaseExpenseAdvanceRepository({
    required this._databaseServices,
    required this._currentUserId,
    this._now = DateTime.now,
    this.timeout = const Duration(seconds: 20),
  });

  final DatabaseServices _databaseServices;
  final String? Function() _currentUserId;
  final DateTime Function() _now;

  /// Longest wait for one request before its outcome is treated as unknown.
  final Duration timeout;

  static const _table = 'expense_advance_requests';

  /// For each sent draft whose result is not known yet: the ids of matching
  /// requests that existed before it was first sent.
  final Map<(String, ExpenseAdvanceDraft), Set<String>> _knownBefore = {};

  static final _currencyPattern = RegExp(r'^[A-Z]{3}$');

  @override
  Future<List<ExpenseAdvanceRequestEntity>> getRequests({
    int limit = 200,
  }) async {
    final userId = _requireUser();
    final rows = await _guard(
      _table,
      () => _databaseServices.getData(
        path: _table,
        column: ExpenseAdvanceRequestModel.columns,
        query: {'employee_id': userId},
        orderBy: 'created_at',
        descending: true,
        limit: limit,
      ),
    );
    return _parse(rows);
  }

  @override
  Future<ExpenseAdvanceRequestEntity> submit(ExpenseAdvanceDraft draft) async {
    final userId = _requireUser();
    _validate(draft);

    final key = (userId, draft);
    // Nothing is sent if these reads fail.
    var known = _knownBefore[key];
    if (known != null) {
      final saved = await _newMatch(userId, draft, known);
      if (saved != null) {
        _knownBefore.remove(key);
        return saved;
      }
    } else {
      known = {for (final r in await _matching(userId, draft)) r.id};
      _knownBefore[key] = known;
    }

    final Object? id;
    try {
      id = await _guard(
        'request_expense_advance',
        () => _databaseServices.rpc(
          function: 'request_expense_advance',
          params: {
            'p_amount': draft.amount,
            'p_reason': draft.reason,
            'p_currency': draft.currency,
          },
        ),
      );
    } on RequestFailure catch (failure) {
      if (failure != RequestFailure.network) {
        // Refused: nothing was saved.
        _knownBefore.remove(key);
        rethrow;
      }
      final ExpenseAdvanceRequestEntity? saved;
      try {
        saved = await _newMatch(userId, draft, known);
      } on RequestFailure {
        throw RequestFailure.outcomeUnknown;
      }
      if (saved == null) rethrow;
      _knownBefore.remove(key);
      return saved;
    }
    _knownBefore.remove(key);
    return _readBack(userId, id, draft);
  }

  @override
  Future<ExpenseAdvanceRequestEntity?> findSubmitted(
    ExpenseAdvanceDraft draft,
  ) async {
    final userId = _requireUser();
    final key = (userId, draft);
    final known = _knownBefore[key];
    if (known == null) return null;
    final saved = await _newMatch(userId, draft, known);
    if (saved != null) _knownBefore.remove(key);
    return saved;
  }

  static void _validate(ExpenseAdvanceDraft draft) {
    final cents = draft.amount * 100;
    if (draft.amount <= 0 || (cents - cents.round()).abs() > 1e-6) {
      throw RequestFailure.invalidAmount;
    }
    if (!_currencyPattern.hasMatch(draft.currency)) {
      throw RequestFailure.invalidCurrency;
    }
    final reasonLength = draft.reason.runes.length;
    if (reasonLength < 1 || reasonLength > 2000) {
      throw RequestFailure.invalidReason;
    }
  }

  /// A pending request with the draft's content that is not in [known].
  Future<ExpenseAdvanceRequestEntity?> _newMatch(
    String userId,
    ExpenseAdvanceDraft draft,
    Set<String> known,
  ) async => (await _matching(
    userId,
    draft,
  )).where((request) => !known.contains(request.id)).firstOrNull;

  /// The employee's recent pending requests with the draft's content.
  Future<List<ExpenseAdvanceRequestEntity>> _matching(
    String userId,
    ExpenseAdvanceDraft draft,
  ) async {
    final rows = await _guard(
      _table,
      () => _databaseServices.getData(
        path: _table,
        column: ExpenseAdvanceRequestModel.columns,
        query: {'employee_id': userId, 'status': 'pending'},
        orderBy: 'created_at',
        descending: true,
        limit: 100,
      ),
    );
    return _parse(rows).where((request) => request.matches(draft)).toList();
  }

  /// The saved request, or one built from [draft] if it can't be read back.
  /// Either way it is pending: only an administrator decides.
  Future<ExpenseAdvanceRequestEntity> _readBack(
    String userId,
    Object? id,
    ExpenseAdvanceDraft draft,
  ) async {
    if (id is String) {
      try {
        final rows = await _guard(
          _table,
          () => _databaseServices.getData(
            path: _table,
            column: ExpenseAdvanceRequestModel.columns,
            query: {'id': id, 'employee_id': userId},
          ),
        );
        final saved = _parse(rows).firstOrNull;
        if (saved != null) return saved;
      } on RequestFailure {
        // Saved; shown from the draft until the list is reloaded.
      }
    }
    return ExpenseAdvanceRequestEntity(
      id: id is String ? id : '',
      amount: draft.amount,
      currency: draft.currency,
      reason: draft.reason,
      status: RequestStatus.pending,
      createdAt: _now(),
    );
  }

  String _requireUser() =>
      _currentUserId() ?? (throw RequestFailure.accountNotReady);

  static List<ExpenseAdvanceRequestEntity> _parse(Object? rows) {
    try {
      return [
        for (final row in (rows as List).cast<Map>())
          ExpenseAdvanceRequestModel.fromJson(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      // Malformed data: show an error rather than a wrong status.
      log('Unreadable cash requests: ${e.runtimeType}');
      throw RequestFailure.unknown;
    }
  }

  /// Runs one request with the timeout and turns its errors into failures.
  Future<Object?> _guard(
    String name,
    Future<dynamic> Function() request,
  ) async {
    try {
      return await request().timeout(timeout);
    } on PostgrestException catch (e) {
      log('$name failed: code ${e.code}');
      throw RequestFailure.fromDatabase(e.code, e.message);
    } on RequestFailure {
      rethrow;
    } on Exception catch (e) {
      // No answer (offline, timeout): the request may still have been saved.
      log('$name failed: ${e.runtimeType}');
      throw RequestFailure.network;
    }
  }
}
