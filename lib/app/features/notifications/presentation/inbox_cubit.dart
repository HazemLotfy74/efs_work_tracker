import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/inbox_repository.dart';

typedef InboxState = ({
  List<InboxNotification> items,
  int unread,
  bool loading,
  bool failed,
  bool more,
});

const InboxState _empty = (
  items: [],
  unread: 0,
  loading: false,
  failed: false,
  more: false,
);

/// The signed-in account's notifications and unread count, for the Alerts
/// tab and its badge. Lives as long as the app, so it keeps listening while
/// the user is on other screens.
class InboxCubit extends Cubit<InboxState> {
  InboxCubit(this.repository) : super(_empty);

  final InboxRepository repository;
  String? _recipient;
  int _generation = 0;
  StreamSubscription<void>? _live;

  void userChanged(String? recipient) {
    if (_recipient == recipient) return;
    _recipient = recipient;
    _generation++;
    // One live subscription, for the current account only.
    _live?.cancel();
    _live = null;
    emit(_empty);
    if (recipient == null) return;
    refresh();
    _live = repository
        .watch(recipient)
        .listen((_) => refresh(quiet: true), onError: (Object _) {});
  }

  /// Reloads the first page and the unread count; [more] loads the next
  /// page instead.
  ///
  /// [quiet] is for updates the user didn't ask for (a live event, the
  /// periodic check): no progress bar, no error banner, and pages already
  /// loaded below the first stay where they are.
  Future<void> refresh({bool more = false, bool quiet = false}) async {
    final recipient = _recipient;
    if (recipient == null || (more && (state.loading || !state.more))) return;
    // A quiet update must not cancel a load the user is waiting for.
    if (quiet && state.loading) return;
    final generation = ++_generation;
    final previous = state;
    final offset = more ? previous.items.length : 0;
    if (!quiet) {
      emit((
        items: previous.items,
        unread: previous.unread,
        loading: true,
        failed: false,
        more: previous.more,
      ));
    }
    try {
      final (rows, unread) = await (
        repository.list(recipient, offset),
        repository.unreadCount(recipient),
      ).wait;
      if (isClosed || generation != _generation) return;
      final keepOlderPages =
          more || (quiet && previous.items.length > InboxRepository.pageSize);
      final List<InboxNotification> items;
      if (!keepOlderPages) {
        items = rows;
      } else if (more) {
        items = {
          for (final row in previous.items) row.id: row,
          for (final row in rows) row.id: row,
        }.values.toList();
      } else {
        // The fresh first page, then what was already loaded further down.
        final fresh = {for (final row in rows) row.id};
        items = [
          ...rows,
          for (final row in previous.items)
            if (!fresh.contains(row.id)) row,
        ];
      }
      emit((
        items: items,
        unread: unread,
        loading: false,
        failed: false,
        more: quiet && keepOlderPages
            ? previous.more
            : rows.length == InboxRepository.pageSize &&
                  (!more || items.length > offset),
      ));
    } catch (_) {
      if (isClosed || generation != _generation || quiet) return;
      emit((
        items: previous.items,
        unread: previous.unread,
        loading: false,
        failed: true,
        more: previous.more,
      ));
    }
  }

  Future<Map<String, dynamic>?> open(InboxNotification item) async {
    final recipient = _recipient;
    if (recipient == null || !state.items.any((row) => row.id == item.id)) {
      return null;
    }
    if (item.unread) {
      if (!await repository.markRead(item.id)) return null;
      if (isClosed || _recipient != recipient) return null;
      await refresh();
    }
    if (isClosed || _recipient != recipient) return null;
    final result = await repository.request(item);
    return !isClosed && _recipient == recipient ? result : null;
  }

  @override
  Future<void> close() async {
    await _live?.cancel();
    return super.close();
  }
}
