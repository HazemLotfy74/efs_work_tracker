import 'dart:async';

import 'package:efs_work_tracker/app/features/cash_request/data/repositories/supabase_expense_advance_repository.dart';
import 'package:efs_work_tracker/app/features/cash_request/domain/entities/expense_advance_request_entity.dart';
import 'package:efs_work_tracker/app/features/cash_request/presentation/manager/cash_request_submit_cubit/cash_request_submit_cubit.dart';
import 'package:efs_work_tracker/app/features/cash_request/presentation/manager/cash_requests_cubit/cash_requests_cubit.dart';
import 'package:efs_work_tracker/app/features/cash_request/presentation/widgets/money_text.dart';
import 'package:efs_work_tracker/core/enums/request_status.dart';
import 'package:efs_work_tracker/core/errors/request_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/fake_request_database.dart';

const _me = 'employee-1';
const _other = 'employee-2';

Map<String, dynamic> _row({
  required String id,
  String employee = _me,
  num amount = 250,
  String currency = 'EGP',
  String reason = 'Client visit transport',
  String status = 'pending',
  String createdAt = '2026-10-28T10:00:00Z',
}) => {
  'id': id,
  'employee_id': employee,
  'requested_amount': amount,
  'currency': currency,
  'reason': reason,
  'status': status,
  'created_at': createdAt,
  'reviewed_at': status == 'pending' ? null : '2026-10-29T08:00:00Z',
  'review_note': null,
};

ExpenseAdvanceDraft _draft({num amount = 250}) =>
    ExpenseAdvanceDraft(amount: amount, reason: ' Client visit transport ');

void main() {
  late FakeRequestDatabase db;
  late SupabaseExpenseAdvanceRepository repository;
  var nextId = 0;

  /// What `request_expense_advance` does: saves a pending row.
  String save(Map<String, dynamic>? params) {
    final id = 'saved-${++nextId}';
    db.rows.add(
      _row(
        id: id,
        amount: params!['p_amount'] as num,
        currency: params['p_currency'] as String,
        reason: params['p_reason'] as String,
        createdAt: '2026-10-28T15:00:0${nextId}Z',
      ),
    );
    return id;
  }

  setUp(() {
    nextId = 0;
    db = FakeRequestDatabase('expense_advance_requests');
    db.onRpc = (_, params) => save(params);
    repository = SupabaseExpenseAdvanceRepository(
      databaseServices: db,
      currentUserId: () => _me,
      timeout: const Duration(seconds: 1),
    );
  });

  group('SupabaseExpenseAdvanceRepository', () {
    test('lists only the employee’s own requests', () async {
      db.rows.addAll([_row(id: 'a'), _row(id: 'b', employee: _other)]);

      final requests = await repository.getRequests();

      expect(requests.map((r) => r.id), ['a']);
      expect(db.readQueries.single, {'employee_id': _me});
    });

    test(
      'sends amount, trimmed reason and EGP, and returns it pending',
      () async {
        final request = await repository.submit(_draft(amount: 250.5));

        final (function, params) = db.rpcCalls.single;
        expect(function, 'request_expense_advance');
        expect(params, {
          'p_amount': 250.5,
          'p_reason': 'Client visit transport',
          'p_currency': 'EGP',
        });
        expect(request.id, 'saved-1');
        expect(request.status, RequestStatus.pending);
      },
    );

    test('a lost answer is matched to the request it saved', () async {
      // An identical request sent earlier must not be mistaken for it.
      db.rows.add(_row(id: 'earlier'));
      db.onRpc = (_, params) {
        save(params);
        throw TimeoutException('answer lost');
      };

      final request = await repository.submit(_draft());

      expect(request.id, 'saved-1');
      expect(db.rpcCalls, hasLength(1));
    });

    test('an identical earlier request is not taken as this send', () async {
      db.rows.add(_row(id: 'earlier'));
      db.onRpc = (_, _) => throw TimeoutException('not sent');

      await expectLater(
        repository.submit(_draft()),
        throwsA(RequestFailure.network),
      );
      expect(await repository.findSubmitted(_draft()), isNull);
    });

    test('a retry after an unknown outcome does not send twice', () async {
      db.onRpc = (_, params) {
        save(params);
        db.failReads = true;
        throw TimeoutException('answer lost');
      };
      await expectLater(
        repository.submit(_draft()),
        throwsA(RequestFailure.outcomeUnknown),
      );

      db.failReads = false;
      db.onRpc = (_, params) => save(params);
      final request = await repository.submit(_draft());

      expect(request.id, 'saved-1');
      expect(db.rpcCalls, hasLength(1));
    });

    test('checks the amount before sending', () async {
      await expectLater(
        repository.submit(_draft(amount: 10.005)),
        throwsA(RequestFailure.invalidAmount),
      );
      await expectLater(
        repository.submit(_draft(amount: 0)),
        throwsA(RequestFailure.invalidAmount),
      );
      expect(db.rpcCalls, isEmpty);
    });

    test('database errors become typed failures', () async {
      db.onRpc = (_, _) => throw const PostgrestException(
        message: 'Amount must have at most two decimal places',
        code: '22023',
      );
      await expectLater(
        repository.submit(_draft()),
        throwsA(RequestFailure.invalidAmount),
      );
      expect(
        RequestFailure.fromDatabase(
          '23514',
          'new row for relation "expense_advance_requests" violates check '
              'constraint "expense_advance_requests_currency_check"',
        ),
        RequestFailure.invalidCurrency,
      );
    });
  });

  group('CashRequestSubmitCubit', () {
    test('a second tap while sending sends nothing', () async {
      db.rpcGate = Completer();
      final cubit = CashRequestSubmitCubit(repository);

      final first = cubit.submit(_draft());
      final second = cubit.submit(_draft());
      await Future<void>.delayed(Duration.zero);
      db.rpcGate!.complete();
      await Future.wait([first, second]);

      expect(db.rpcCalls, hasLength(1));
      expect(cubit.state, isA<CashRequestSubmitted>());
      await cubit.close();
    });

    test('looks for the earlier send before retrying', () async {
      db.onRpc = (_, params) {
        save(params);
        db.failReads = true;
        throw TimeoutException('answer lost');
      };
      final cubit = CashRequestSubmitCubit(repository);

      await cubit.submit(_draft());
      expect(
        (cubit.state as CashRequestSubmitFailed).failure,
        RequestFailure.outcomeUnknown,
      );
      db.failReads = false;
      await cubit.submit(_draft());

      expect((cubit.state as CashRequestSubmitted).request.id, 'saved-1');
      expect(db.rpcCalls, hasLength(1));
      await cubit.close();
    });
  });

  group('CashRequestsCubit', () {
    test('filters by status and totals pending amounts', () async {
      db.rows.addAll([
        _row(id: 'p1', amount: 250, createdAt: '2026-10-03T10:00:00Z'),
        _row(id: 'p2', amount: 100.5, createdAt: '2026-10-02T10:00:00Z'),
        _row(id: 'a', status: 'approved', createdAt: '2026-10-01T10:00:00Z'),
      ]);
      final cubit = CashRequestsCubit(repository);

      await cubit.load();
      expect((cubit.state as CashRequestsLoaded).pendingTotals, {'EGP': 350.5});

      cubit.filterBy(RequestStatus.approved);
      expect((cubit.state as CashRequestsLoaded).visible.map((r) => r.id), [
        'a',
      ]);
      await cubit.close();
    });
  });

  test('parseAmount accepts Arabic digits and decimal commas', () {
    expect(parseAmount('٢٥٠٫٥'), 250.5);
    expect(parseAmount('12,75'), 12.75);
    expect(parseAmount(' 1000 '), 1000);
    expect(parseAmount('1.234'), isNull);
    expect(parseAmount('-5'), isNull);
    expect(parseAmount('abc'), isNull);
  });
}
