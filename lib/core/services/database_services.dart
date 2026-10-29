abstract class DatabaseServices {
  Future<void> addData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  });
  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  });

  /// Rows of [path] matching [query] (equality filters), or the one row with
  /// id [documentId] (`null` if none). Lists can be sorted by [orderBy] and
  /// capped at [limit].
  Future<dynamic> getData({
    required String path,
    String? documentId,
    String? column,
    Map<String, dynamic>? query,
    String? orderBy,
    bool descending = false,
    int? limit,
  });
  Stream<dynamic> getStreamData({
    required String path,
    String? documentId,
    Map<String, dynamic>? query,
  });
  Future<bool> ifDataExist({required String path, required String documentId});

  Future<void> deleteData({
    required String path,
    String? documentId,
    Map<String, dynamic>? query,
  });

  /// Calls a database function. In this project every write and the
  /// account status go through functions, not table writes.
  Future<dynamic> rpc({required String function, Map<String, dynamic>? params});
}
