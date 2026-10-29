import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/admin_repository.dart';
import '../manager/add_employee_cubit/add_employee_cubit.dart';
import '../widgets/add_employee_view_body.dart';

/// Admin only: creates an employee account.
class AddEmployeeView extends StatelessWidget {
  const AddEmployeeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AddEmployeeCubit(context.read<AdminRepository>())..load(),
      child: const Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
          child: AddEmployeeViewBody(),
        ),
      ),
    );
  }
}
