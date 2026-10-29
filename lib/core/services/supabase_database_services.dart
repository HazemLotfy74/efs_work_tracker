import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/constants.dart';
import 'database_services.dart';

/// [DatabaseServices] on Supabase. `path` is the table name and
/// `documentId` matches its `id` column.
///
/// Row Level Security only allows reads on this project's tables, so the
/// write methods fail there; use [rpc] for writes.
class SupabaseDatabaseServices implements DatabaseServices {
  SupabaseClient get _client => Constants.supabase;

  @override
  Future<void> addData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    await _client
        .from(path)
        .insert(documentId == null ? data : {...data, 'id': documentId});
  }

  @override
  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    var builder = _client.from(path).update(data);
    if (documentId != null) builder = builder.eq('id', documentId);
    await builder;
  }

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
    var builder = _client.from(path).select(column ?? '*');
    query?.forEach((key, value) => builder = builder.eq(key, value as Object));
    if (documentId != null) {
      return await builder.eq('id', documentId).maybeSingle();
    }
    PostgrestTransformBuilder<PostgrestList> list = builder;
    if (orderBy != null) list = list.order(orderBy, ascending: !descending);
    if (limit != null) list = list.limit(limit);
    return await list;
  }

  @override
  Stream<dynamic> getStreamData({
    required String path,
    String? documentId,
    Map<String, dynamic>? query,
  }) {
    final stream = _client.from(path).stream(primaryKey: ['id']);
    if (documentId != null) return stream.eq('id', documentId);
    return stream;
  }

  @override
  Future<bool> ifDataExist({
    required String path,
    required String documentId,
  }) async {
    final row = await _client
        .from(path)
        .select('id')
        .eq('id', documentId)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<void> deleteData({
    required String path,
    String? documentId,
    Map<String, dynamic>? query,
  }) async {
    var builder = _client.from(path).delete();
    if (documentId != null) builder = builder.eq('id', documentId);
    query?.forEach((key, value) => builder = builder.eq(key, value as Object));
    await builder;
  }

  @override
  Future<dynamic> rpc({
    required String function,
    Map<String, dynamic>? params,
  }) {
    return _client.rpc(function, params: params);
  }
}
