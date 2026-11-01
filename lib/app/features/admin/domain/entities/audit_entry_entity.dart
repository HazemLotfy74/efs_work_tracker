/// One changed field of an audited row.
typedef AuditChange = ({String field, Object? before, Object? after});

/// One row of `audit_logs`: the database writes it itself (triggers on
/// every business table) and nobody can edit or delete it.
class AuditEntryEntity {
  const AuditEntryEntity({
    required this.id,
    required this.actorId,
    required this.actorKind,
    required this.action,
    required this.table,
    required this.rowId,
    required this.happenedAt,
    required this.changes,
  });

  final int id;

  /// Who made the change; `null` for the system (e.g. automatic close).
  final String? actorId;

  /// `user`, `system` or `database`.
  final String actorKind;

  /// `INSERT`, `UPDATE` or `DELETE`.
  final String action;
  final String table;
  final String? rowId;
  final DateTime happenedAt;

  /// The fields that differ between the old and new row (every field of
  /// an insert), without bookkeeping columns.
  final List<AuditChange> changes;

  /// Columns that change on every write and say nothing to a reviewer.
  static const ignoredFields = {'updated_at', 'created_at', 'id'};

  /// The fields that differ between [before] and [after].
  static List<AuditChange> diff(
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  ) {
    final fields = {...?before?.keys, ...?after?.keys}
      ..removeAll(ignoredFields);
    return [
      for (final field in fields.toList()..sort())
        if ('${before?[field]}' != '${after?[field]}')
          (field: field, before: before?[field], after: after?[field]),
    ];
  }
}
