import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../attendance_session/domain/repositories/attendance_repository.dart';
import '../../../home/presentation/manager/attendance_details_cubit/attendance_details_cubit.dart';
import '../../domain/repositories/correction_repository.dart';
import '../manager/correction_form_cubit/correction_form_cubit.dart';
import '../widgets/correction_form_view_body.dart';

/// The correction request form for the attendance day [id]. The day is
/// loaded again, so the route works on its own (deep link, restart).
/// Pops `true` once the request was sent.
class CorrectionFormView extends StatelessWidget {
  const CorrectionFormView({super.key, required this.id});

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
        BlocProvider(
          create: (context) =>
              CorrectionFormCubit(context.read<CorrectionRepository>()),
        ),
      ],
      child: const Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
          child: CorrectionFormViewBody(),
        ),
      ),
    );
  }
}
