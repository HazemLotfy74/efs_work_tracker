import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/admin_repository.dart';
import '../manager/admin_dashboard_cubit/admin_dashboard_cubit.dart';
import '../widgets/admin_dashboard_view_body.dart';

/// Admin only (the router sends everyone else home): today's attendance
/// of every employee, and the admin tools.
class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AdminDashboardCubit(context.read<AdminRepository>())..load(),
      child: const Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
          child: AdminDashboardViewBody(),
        ),
      ),
    );
  }
}
