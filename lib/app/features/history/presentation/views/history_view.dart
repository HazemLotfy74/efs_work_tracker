import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../attendance_session/domain/repositories/attendance_repository.dart';
import '../../../attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';
import '../manager/attendance_history_cubit/attendance_history_cubit.dart';
import '../widgets/history_view_body.dart';

/// History tab: the employee's attendance days, newest first.
class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AttendanceHistoryCubit(context.read<AttendanceRepository>())..load(),
      // Today's check-in or check-out changes the list.
      child: BlocListener<AttendanceSessionCubit, AttendanceSessionState>(
        listenWhen: (previous, current) =>
            current is AttendanceSessionLoaded && previous != current,
        listener: (context, _) => context.read<AttendanceHistoryCubit>().load(),
        child: const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: HistoryViewBody(),
            ),
          ),
        ),
      ),
    );
  }
}
