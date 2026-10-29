import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../attendance_correction/domain/repositories/correction_repository.dart';
import '../../../attendance_correction/presentation/manager/correction_requests_cubit/correction_requests_cubit.dart';
import '../../../attendance_session/domain/repositories/attendance_repository.dart';
import '../manager/attendance_details_cubit/attendance_details_cubit.dart';
import '../widgets/attendance_details_view_body.dart';

/// Details of one attendance day; the router passes its record [id].
class AttendanceDetailsView extends StatelessWidget {
  const AttendanceDetailsView({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AttendanceDetailsCubit(context.read<AttendanceRepository>(), id)
                ..load(),
        ),
        // Lazy: created (and loaded) only when the correction section shows.
        BlocProvider(
          create: (context) =>
              CorrectionRequestsCubit(context.read<CorrectionRepository>(), id)
                ..load(),
        ),
      ],
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
          child: AttendanceDetailsViewBody(),
        ),
      ),
    );
  }
}
