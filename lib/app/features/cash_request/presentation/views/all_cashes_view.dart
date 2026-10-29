import 'package:efs_work_tracker/app/features/cash_request/presentation/widgets/all_cashes_view_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/expense_advance_repository.dart';
import '../manager/cash_requests_cubit/cash_requests_cubit.dart';

/// The employee's cash advance requests, newest first.
class AllCashesView extends StatelessWidget {
  const AllCashesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CashRequestsCubit(context.read<ExpenseAdvanceRepository>())..load(),
      child: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
            child: AllCashesViewBody(),
          ),
        ),
      ),
    );
  }
}
