import 'package:supabase_flutter/supabase_flutter.dart';

enum RequestKind {
  expenseAdvance('expense_advance', 'expense_advance_requests'),
  overtime('overtime', 'overtime_requests'),
  correction('correction', 'attendance_correction_requests');

  const RequestKind(this.value, this.table);
  final String value;
  final String table;
}

enum InboxEvent { submitted, assigned, approved, rejected }

class InboxNotification {
  InboxNotification.fromJson(Map<String, dynamic> row)
    : id = row['id'] as String,
      kind = RequestKind.values.firstWhere(
        (kind) => kind.value == row['request_kind'],
      ),
      requestId = row['request_id'] as String,
      event = InboxEvent.values.byName(row['event_type'] as String),
      createdAt = DateTime.parse(row['created_at'] as String),
      unread = row['read_at'] == null;

  final String id;
  final RequestKind kind;
  final String requestId;
  final InboxEvent event;
  final DateTime createdAt;
  final bool unread;
}

class InboxRepository {
  InboxRepository(this.client);
  final SupabaseClient client;
  static const pageSize = 50;

  Future<List<InboxNotification>> list(String recipient, int offset) async {
    final rows = await client
        .from('notifications')
        .select('id,request_kind,request_id,event_type,created_at,read_at')
        .eq('recipient_id', recipient)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + pageSize - 1)
        .timeout(const Duration(seconds: 15));
    return rows.map(InboxNotification.fromJson).toList();
  }

  Future<int> unreadCount(String recipient) => client
      .from('notifications')
      .count(CountOption.exact)
      .eq('recipient_id', recipient)
      .isFilter('read_at', null)
      .timeout(const Duration(seconds: 15));

  Future<bool> markRead(String id) async =>
      await client
          .rpc('mark_notification_read', params: {'p_notification_id': id})
          .timeout(const Duration(seconds: 15)) ==
      true;

  /// Request policies remain authoritative after reassignment or revocation.
  Future<Map<String, dynamic>?> request(InboxNotification item) => client
      .from(item.kind.table)
      .select('id,status,reason')
      .eq('id', item.requestId)
      .maybeSingle()
      .timeout(const Duration(seconds: 15));
}
