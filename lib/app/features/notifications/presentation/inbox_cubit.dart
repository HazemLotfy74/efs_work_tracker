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

class InboxCubit extends Cubit<InboxState> {
  InboxCubit(this.repository) : super(_empty);

  final InboxRepository repository;
  String? _recipient;
  int _generation = 0;

  void userChanged(String? recipient) {
    if (_recipient == recipient) return;
    _recipient = recipient;
    _generation++;
    emit(_empty);
    if (recipient != null) refresh();
  }

  Future<void> refresh({bool more = false}) async {
    final recipient = _recipient;
    if (recipient == null || (more && (state.loading || !state.more))) return;
    final generation = ++_generation;
    final previous = state;
    final offset = more ? previous.items.length : 0;
    emit((
      items: previous.items,
      unread: previous.unread,
      loading: true,
      failed: false,
      more: previous.more,
    ));
    try {
      final (rows, unread) = await (
        repository.list(recipient, offset),
        repository.unreadCount(recipient),
      ).wait;
      if (isClosed || generation != _generation) return;
      final items = more
          ? {
              for (final row in previous.items) row.id: row,
              for (final row in rows) row.id: row,
            }.values.toList()
          : rows;
      emit((
        items: items,
        unread: unread,
        loading: false,
        failed: false,
        more:
            rows.length == InboxRepository.pageSize &&
            (!more || items.length > offset),
      ));
    } catch (_) {
      if (isClosed || generation != _generation) return;
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
    if (recipient == null || !state.items.any((row) => row.id == item.id))
      return null;
    if (item.unread) {
      if (!await repository.markRead(item.id)) return null;
      if (isClosed || _recipient != recipient) return null;
      await refresh();
    }
    if (isClosed || _recipient != recipient) return null;
    final result = await repository.request(item);
    return !isClosed && _recipient == recipient ? result : null;
  }
}
