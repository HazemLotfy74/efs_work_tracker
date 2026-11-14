import 'dart:async';

import 'package:efs_work_tracker/app/features/notifications/data/inbox_repository.dart';
import 'package:efs_work_tracker/app/features/notifications/presentation/inbox_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _Inbox extends Fake implements InboxRepository {
  bool read = false;
  bool requestVisible = true;
  final delayed = Completer<List<InboxNotification>>();

  @override
  Future<List<InboxNotification>> list(String recipient, int offset) async {
    if (recipient == 'slow') return delayed.future;
    return [_item(read)];
  }

  @override
  Future<int> unreadCount(String recipient) async => read ? 0 : 1;

  @override
  Stream<void> watch(String recipient) => const Stream.empty();

  @override
  Future<bool> markRead(String id) async {
    expect(id, 'notification');
    read = true;
    return true;
  }

  @override
  Future<Map<String, dynamic>?> request(InboxNotification item) async =>
      requestVisible ? {'id': item.requestId, 'status': 'approved'} : null;
}

InboxNotification _item(bool read) => InboxNotification.fromJson({
  'id': 'notification',
  'request_kind': 'expense_advance',
  'request_id': 'request',
  'event_type': 'approved',
  'created_at': '2026-11-12T10:00:00Z',
  'read_at': read ? '2026-11-12T10:01:00Z' : null,
});

void main() {
  test(
    'opening an alert marks it read even if request access was revoked',
    () async {
      final repo = _Inbox()..requestVisible = false;
      final cubit = InboxCubit(repo);
      addTearDown(cubit.close);
      final loaded = cubit.stream.firstWhere((state) => state.items.isNotEmpty);
      cubit.userChanged('recipient');
      await loaded;
      expect(cubit.state.unread, 1);
      expect(await cubit.open(cubit.state.items.single), isNull);
      expect(cubit.state.items.single.unread, isFalse);
      expect(cubit.state.unread, 0);
    },
  );

  test(
    'a late response cannot restore another user’s inbox after sign-out',
    () async {
      final repo = _Inbox();
      final cubit = InboxCubit(repo);
      addTearDown(cubit.close);
      cubit.userChanged('slow');
      cubit.userChanged(null);
      repo.delayed.complete([_item(false)]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.unread, 0);
    },
  );
}
