import 'dart:async';

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

  /// `null` for a row this version of the app can't show (a request type or
  /// event added to the database later). One such row must not empty the
  /// whole list.
  static InboxNotification? tryFromJson(Map<String, dynamic> row) {
    try {
      return InboxNotification.fromJson(row);
    } catch (_) {
      return null;
    }
  }

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
    return rows.map(InboxNotification.tryFromJson).nonNulls.toList();
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

  /// Fires whenever [recipient]'s notifications change on the server, and
  /// each time the live connection opens (first connect, and again after the
  /// internet comes back, so anything missed meanwhile is fetched).
  ///
  /// Supabase Realtime, over the row-level security of `notifications`: the
  /// server only sends an account its own rows. It carries no data here; the
  /// listener reloads the list. One channel per listener, removed on cancel.
  /// Needs `notifications` in the `supabase_realtime` publication
  /// (supabase/migrations/20261113100000_notifications_realtime.sql); until
  /// then the stream is silent and the app's periodic refresh does the work.
  Stream<void> watch(String recipient) {
    late final StreamController<void> controller;
    RealtimeChannel? channel;
    void changed() {
      if (!controller.isClosed) controller.add(null);
    }

    controller = StreamController<void>(
      onListen: () {
        channel = client
            .channel('inbox-$recipient')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'recipient_id',
                value: recipient,
              ),
              callback: (_) => changed(),
            )
            .subscribe((status, _) {
              if (status == RealtimeSubscribeStatus.subscribed) changed();
            });
      },
      onCancel: () async {
        final open = channel;
        channel = null;
        if (open != null) await client.removeChannel(open);
      },
    );
    return controller.stream;
  }

  /// Request policies remain authoritative after reassignment or revocation.
  Future<Map<String, dynamic>?> request(InboxNotification item) => client
      .from(item.kind.table)
      // review_note: the reviewer's reason, shown with a decision.
      .select('id,status,reason,review_note')
      .eq('id', item.requestId)
      .maybeSingle()
      .timeout(const Duration(seconds: 15));
}
