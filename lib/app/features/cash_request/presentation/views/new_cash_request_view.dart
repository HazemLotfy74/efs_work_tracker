import 'package:efs_work_tracker/app/features/cash_request/presentation/widgets/new_cash_request_view_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/expense_advance_repository.dart';
import '../manager/cash_request_submit_cubit/cash_request_submit_cubit.dart';

/// New cash advance request. Pops with the saved request once it is sent.
class NewCashRequestView extends StatelessWidget {
  const NewCashRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CashRequestSubmitCubit(context.read<ExpenseAdvanceRepository>()),
      child: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
            child: NewCashRequestViewBody(),
          ),
        ),
      ),
    );
  }
}
