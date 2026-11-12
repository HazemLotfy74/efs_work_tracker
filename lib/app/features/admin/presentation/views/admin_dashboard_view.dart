import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/admin_repository.dart';
import '../manager/admin_dashboard_cubit/admin_dashboard_cubit.dart';
import '../../../permissions/domain/entities/permission_set.dart';
import '../../../permissions/presentation/permissions_context.dart';
import '../widgets/admin_dashboard_view_body.dart';

/// The admin area (the router sends anyone without an admin permission home):
/// with employees.view and attendance.view_all, today's attendance
/// of every employee, and the admin tools.
class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final can = context.permissions;
    final overview =
        can.can(Permission.employeesView) &&
        can.can(Permission.attendanceViewAll);
    return BlocProvider(
      create: (context) {
        final cubit = AdminDashboardCubit(context.read<AdminRepository>());
        if (overview) cubit.load();
        return cubit;
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
          child: AdminDashboardViewBody(overview: overview),
        ),
      ),
    );
  }
}
