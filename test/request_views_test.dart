import 'package:efs_work_tracker/app/features/cash_request/data/repositories/supabase_expense_advance_repository.dart';
import 'package:efs_work_tracker/app/features/cash_request/domain/repositories/expense_advance_repository.dart';
import 'package:efs_work_tracker/app/features/cash_request/presentation/views/all_cashes_view.dart';
import 'package:efs_work_tracker/core/theme/app_theme.dart';
import 'package:efs_work_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_request_database.dart';

Widget _app(Widget home, {required FakeRequestDatabase db}) =>
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ExpenseAdvanceRepository>.value(
          value: SupabaseExpenseAdvanceRepository(
            databaseServices: db,
            currentUserId: () => 'employee-1',
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: home,
      ),
    );

void main() {
  testWidgets('cash list shows the pending total', (tester) async {
    final db = FakeRequestDatabase('expense_advance_requests')
      ..rows.add({
        'id': 'c',
        'employee_id': 'employee-1',
        'requested_amount': 250,
        'currency': 'EGP',
        'reason': 'Client visit transport',
        'status': 'pending',
        'created_at': '2026-10-28T10:00:00Z',
        'reviewed_at': null,
        'review_note': null,
      });

    await tester.pumpWidget(_app(const AllCashesView(), db: db));
    await tester.pumpAndSettle();

    expect(find.text('250 EGP'), findsNWidgets(2));
    expect(find.text('Client visit transport'), findsOneWidget);
  });
}
