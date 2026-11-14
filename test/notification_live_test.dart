import 'dart:async';

import 'package:efs_work_tracker/app/features/notifications/data/inbox_repository.dart';
import 'package:efs_work_tracker/app/features/notifications/presentation/inbox_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server-side inbox with a live channel per listener, like
/// `InboxRepository.watch`: [push] is the server telling the phone that the
/// account's notifications changed.
class _LiveInbox extends Fake implements InboxRepository {
  final rows = <String, List<Map<String, dynamic>>>{};
  final channels = <String, List<StreamController<void>>>{};
  int opened = 0;
  int lists = 0;
  bool offline = false;

  void add(String recipient, String id, {String kind = 'correction'}) {
    rows.putIfAbsent(recipient, () => []).insert(0, {
      'id': id,
      'request_kind': kind,
      'request_id': 'r-$id',
      'event_type': 'submitted',
      'created_at': DateTime.utc(2026, 11, 13, 10, rows.length).toIso8601String(),
      'read_at': null,
    });
  }

  /// The live event for [recipient], to every open channel of theirs.
  void push(String recipient) {
    for (final channel in [...?channels[recipient]]) {
      channel.add(null);
    }
  }

  int open(String recipient) => channels[recipient]?.length ?? 0;

  @override
  Stream<void> watch(String recipient) {
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        opened++;
        channels.putIfAbsent(recipient, () => []).add(controller);
      },
      onCancel: () => channels[recipient]?.remove(controller),
    );
    return controller.stream;
  }

  @override
  Future<List<InboxNotification>> list(String recipient, int offset) async {
    lists++;
    if (offline) throw Exception('offline');
    return (rows[recipient] ?? [])
        .skip(offset)
        .take(InboxRepository.pageSize)
        .map(InboxNotification.tryFromJson)
        .nonNulls
        .toList();
  }

  @override
  Future<int> unreadCount(String recipient) async {
    if (offline) throw Exception('offline');
    return (rows[recipient] ?? []).where((r) => r['read_at'] == null).length;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _LiveInbox server;
  late InboxCubit cubit;

  setUp(() {
    server = _LiveInbox();
    cubit = InboxCubit(server);
  });
  tearDown(() => cubit.close());

  test('a new notification shows up and the badge updates, no restart', () async {
    cubit.userChanged('reviewer');
    await _settle();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.unread, 0);

    server.add('reviewer', 'n1');
    server.push('reviewer');
    await _settle();

    expect(cubit.state.items.map((n) => n.id), ['n1']);
    expect(cubit.state.unread, 1);
  });

  test('a live update never shows a progress bar or an error banner', () async {
    cubit.userChanged('reviewer');
    await _settle();
    final seen = <InboxState>[];
    final subscription = cubit.stream.listen(seen.add);

    server.add('reviewer', 'n1');
    server.push('reviewer');
    await _settle();
    server.offline = true;
    server.push('reviewer');
    await _settle();
    await subscription.cancel();

    expect(seen.any((state) => state.loading), isFalse);
    expect(seen.any((state) => state.failed), isFalse);
    // Offline: the list already shown is kept.
    expect(cubit.state.items.map((n) => n.id), ['n1']);
  });

  test('back online: the next event brings what was missed', () async {
    cubit.userChanged('reviewer');
    await _settle();
    server.offline = true;
    server.add('reviewer', 'n1');
    server.push('reviewer');
    await _settle();
    expect(cubit.state.items, isEmpty);

    server.offline = false;
    server.add('reviewer', 'n2');
    // What the live connection sends when it reopens.
    server.push('reviewer');
    await _settle();
    expect(cubit.state.items.map((n) => n.id), ['n2', 'n1']);
    expect(cubit.state.unread, 2);
  });

  test('one subscription per account; none after sign-out', () async {
    cubit.userChanged('a');
    cubit.userChanged('a');
    await _settle();
    expect(server.opened, 1);
    expect(server.open('a'), 1);

    cubit.userChanged('b');
    await _settle();
    expect(server.open('a'), 0, reason: 'the previous account is released');
    expect(server.open('b'), 1);

    cubit.userChanged(null);
    await _settle();
    expect(server.open('b'), 0);
    expect(server.opened, 2);
  });

  test('another account\'s event changes nothing here', () async {
    cubit.userChanged('employee');
    await _settle();
    server.add('reviewer', 'secret');
    server.push('reviewer');
    await _settle();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.unread, 0);
  });

  test('an event after sign-out is ignored', () async {
    cubit.userChanged('reviewer');
    await _settle();
    cubit.userChanged(null);
    server.add('reviewer', 'n1');
    server.push('reviewer');
    await _settle();
    expect(cubit.state.items, isEmpty);
  });

  test('the same notification is never listed twice', () async {
    server.add('reviewer', 'n1');
    cubit.userChanged('reviewer');
    await _settle();
    server.push('reviewer');
    server.push('reviewer');
    await cubit.refresh(quiet: true);
    await _settle();
    expect(cubit.state.items.map((n) => n.id), ['n1']);
  });

  test('pages already loaded stay when a live update arrives', () async {
    for (var i = 0; i < InboxRepository.pageSize + 5; i++) {
      server.add('reviewer', 'old$i');
    }
    cubit.userChanged('reviewer');
    await _settle();
    await cubit.refresh(more: true);
    expect(cubit.state.items, hasLength(InboxRepository.pageSize + 5));

    server.add('reviewer', 'new');
    server.push('reviewer');
    await _settle();
    expect(cubit.state.items.first.id, 'new');
    expect(cubit.state.items, hasLength(InboxRepository.pageSize + 6));
    expect(cubit.state.items.map((n) => n.id).toSet(), hasLength(
      InboxRepository.pageSize + 6,
    ));
  });

  test('a quiet update does not interrupt a load the user started', () async {
    cubit.userChanged('reviewer');
    await _settle();
    final before = server.lists;
    final manual = cubit.refresh();
    await cubit.refresh(quiet: true);
    await manual;
    expect(server.lists, before + 1);
  });

  test('a notification type this app version does not know is skipped', () async {
    server.add('reviewer', 'known');
    server.add('reviewer', 'future', kind: 'leave_request');
    cubit.userChanged('reviewer');
    await _settle();
    expect(cubit.state.items.map((n) => n.id), ['known']);
    expect(cubit.state.failed, isFalse);
  });
}
