import 'dart:async';

import 'package:efs_work_tracker/core/services/database_services.dart';

/// One table in memory, with scripted database functions. Reads apply the
/// equality filters, order and limit like Supabase does.
class FakeRequestDatabase implements DatabaseServices {
  FakeRequestDatabase(this.table);

  final String table;
  final List<Map<String, dynamic>> rows = [];
  final List<(String, Map<String, dynamic>?)> rpcCalls = [];
  final List<Map<String, dynamic>?> readQueries = [];

  /// Answers a function call: returns its result or throws.
  FutureOr<Object?> Function(String function, Map<String, dynamic>? params)?
  onRpc;

  /// Reads throw while this is true (no connection).
  bool failReads = false;

  /// When set, function calls wait for it.
  Completer<void>? rpcGate;

  @override
  Future<dynamic> getData({
    required String path,
    String? documentId,
    String? column,
    Map<String, dynamic>? query,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    if (path != table) throw StateError('Unexpected table $path');
    readQueries.add(query);
    if (failReads) throw TimeoutException('offline');
    var result = rows
        .where(
          (row) => (query ?? {}).entries.every(
            (filter) => '${row[filter.key]}' == '${filter.value}',
          ),
        )
        .map(Map<String, dynamic>.of)
        .toList();
    if (orderBy != null) {
      result.sort((a, b) {
        final order = '${a[orderBy]}'.compareTo('${b[orderBy]}');
        return descending ? -order : order;
      });
    }
    if (limit != null) result = result.take(limit).toList();
    return result;
  }

  @override
  Future<dynamic> rpc({
    required String function,
    Map<String, dynamic>? params,
  }) async {
    rpcCalls.add((function, params));
    await rpcGate?.future;
    return onRpc!(function, params);
  }

  @override
  Future<void> addData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) => throw UnimplementedError('Tables are read-only');

  @override
  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) => throw UnimplementedError('Tables are read-only');

  @override
  Future<void> deleteData({
    required String path,
    String? documentId,
    Map<String, dynamic>? query,
  }) => throw UnimplementedError('Tables are read-only');

  @override
  Stream<dynamic> getStreamData({
    required String path,
    String? documentId,
    Map<String, dynamic>? query,
  }) => throw UnimplementedError();

  @override
  Future<bool> ifDataExist({
    required String path,
    required String documentId,
  }) => throw UnimplementedError();
}
