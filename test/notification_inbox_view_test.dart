import 'package:efs_work_tracker/app/features/notifications/data/inbox_repository.dart';
import 'package:efs_work_tracker/app/features/notifications/presentation/inbox_cubit.dart';
import 'package:efs_work_tracker/app/features/notifications/presentation/inbox_view.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// An inbox held in memory. [rows] are the notifications; [request] is what
/// the database lets the account read of the request behind one.
class _Inbox extends Fake implements InboxRepository {
  _Inbox(this.rows);

  List<Map<String, dynamic>> rows;
  Map<String, dynamic>? visibleRequest = {
    'id': 'r1',
    'status': 'rejected',
    'reason': 'I forgot to check out',
    'review_note': 'The gate log shows 14:00',
  };
  bool fail = false;
  final marked = <String>[];

  @override
  Future<List<InboxNotification>> list(String recipient, int offset) async {
    if (fail) throw Exception('offline');
    return rows.skip(offset).map(InboxNotification.fromJson).toList();
  }

  @override
  Future<int> unreadCount(String recipient) async =>
      rows.where((row) => row['read_at'] == null).length;

  @override
  Stream<void> watch(String recipient) => const Stream.empty();

  @override
  Future<bool> markRead(String id) async {
    marked.add(id);
    rows = [
      for (final row in rows)
        row['id'] == id ? {...row, 'read_at': '2026-11-12T11:00:00Z'} : row,
    ];
    return true;
  }

  @override
  Future<Map<String, dynamic>?> request(InboxNotification item) async =>
      visibleRequest;
}

Map<String, dynamic> _row(
  String id,
  String kind,
  String event, {
  bool read = false,
}) => {
  'id': id,
  'request_kind': kind,
  'request_id': 'r$id',
  'event_type': event,
  'created_at': '2026-11-12T10:00:00Z',
  'read_at': read ? '2026-11-12T10:05:00Z' : null,
};

final _everyKind = [
  _row('1', 'correction', 'rejected'),
  _row('2', 'correction', 'approved', read: true),
  _row('3', 'expense_advance', 'submitted'),
  _row('4', 'overtime', 'assigned', read: true),
];

Future<InboxCubit> _show(
  WidgetTester tester,
  _Inbox inbox, {
  Size size = const Size(390, 844),
  String locale = 'en',
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final cubit = InboxCubit(inbox)..userChanged('me');
  addTearDown(cubit.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        theme: AppTheme.lightFor(Locale(locale)),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const InboxView(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  // Small and large Android phones, small and large iPhones.
  const sizes = {
    'small Android 320x568': Size(320, 568),
    'iPhone SE 375x667': Size(375, 667),
    'iPhone 15 Pro Max 430x932': Size(430, 932),
    'large Android 480x1040': Size(480, 1040),
  };
  for (final MapEntry(key: name, value: size) in sizes.entries) {
    for (final locale in ['ar', 'en']) {
      for (final scale in [1.0, 1.3, 1.6]) {
        testWidgets('list fits $name, $locale, text ${scale}x', (tester) async {
          await _show(
            tester,
            _Inbox(_everyKind),
            size: size,
            locale: locale,
            scale: scale,
          );
          // An overflow is reported as an exception by the test framework.
          expect(tester.takeException(), isNull);
          expect(find.byKey(const ValueKey('1')), findsOneWidget);
        });
      }
    }
  }

  testWidgets('Arabic is laid out right to left', (tester) async {
    await _show(tester, _Inbox(_everyKind), locale: 'ar');
    expect(
      Directionality.of(tester.element(find.byType(InboxView))),
      TextDirection.rtl,
    );
    // Icon at the start (right), unread dot at the end (left).
    final card = tester.getRect(find.byKey(const ValueKey('1')));
    final dot = tester.getCenter(
      find.descendant(
        of: find.byKey(const ValueKey('1')),
        matching: find.byKey(const Key('unreadDot')),
      ),
    );
    expect(dot.dx, lessThan(card.center.dx));
    expect(find.text('طلب التصحيح'), findsWidgets);
  });

  testWidgets('unread and read notifications look different', (tester) async {
    await _show(tester, _Inbox(_everyKind));
    Finder dotIn(String id) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.byKey(const Key('unreadDot')),
    );
    expect(dotIn('1'), findsOneWidget);
    expect(dotIn('3'), findsOneWidget);
    expect(dotIn('2'), findsNothing);
    expect(dotIn('4'), findsNothing);
    // Each request type has its own icon.
    expect(find.byIcon(Icons.edit_calendar_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
    expect(find.byIcon(Icons.more_time_rounded), findsOneWidget);
    // No notification is listed twice.
    expect(find.byType(InkWell), findsNWidgets(4));
  });

  testWidgets('showing the list marks nothing as read', (tester) async {
    final inbox = _Inbox(_everyKind);
    final cubit = await _show(tester, inbox);
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(inbox.marked, isEmpty);
    expect(cubit.state.unread, 2);
  });

  testWidgets('opening one marks only it read and shows the decision reason', (
    tester,
  ) async {
    final inbox = _Inbox(_everyKind);
    final cubit = await _show(tester, inbox);
    await tester.tap(find.byKey(const ValueKey('1')));
    await tester.pumpAndSettle();

    expect(inbox.marked, ['1']);
    expect(cubit.state.unread, 1);
    expect(find.text('Rejected'), findsWidgets);
    expect(find.text('I forgot to check out'), findsOneWidget);
    final reason = find.byKey(const Key('inboxDecisionReason'));
    expect(
      find.descendant(of: reason, matching: find.text('Rejection reason')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reason,
        matching: find.text('The gate log shows 14:00'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('1')),
        matching: find.byKey(const Key('unreadDot')),
      ),
      findsNothing,
    );
  });

  testWidgets('a request the account may no longer read says so', (
    tester,
  ) async {
    final inbox = _Inbox(_everyKind)..visibleRequest = null;
    await _show(tester, inbox);
    await tester.tap(find.byKey(const ValueKey('3')));
    await tester.pumpAndSettle();
    expect(
      find.text('This request is no longer available to you.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inboxDecisionReason')), findsNothing);
  });

  testWidgets('empty, then an error with a retry', (tester) async {
    final inbox = _Inbox([]);
    final cubit = await _show(tester, inbox, size: const Size(320, 568));
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);

    inbox.fail = true;
    await cubit.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t load notifications. Try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    inbox
      ..fail = false
      ..rows = _everyKind;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('1')), findsOneWidget);
  });

  testWidgets('a failed refresh keeps the list and offers a retry', (
    tester,
  ) async {
    final inbox = _Inbox(_everyKind);
    final cubit = await _show(tester, inbox);
    inbox.fail = true;
    await cubit.refresh();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('1')), findsOneWidget);
    expect(find.byTooltip('Retry'), findsOneWidget);
  });
}
