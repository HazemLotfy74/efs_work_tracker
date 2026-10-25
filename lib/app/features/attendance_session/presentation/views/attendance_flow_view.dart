import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/attendance_type.dart';
import '../manager/attendance_flow_cubit/attendance_flow_cubit.dart';
import '../manager/location_cubit/location_cubit.dart';
import '../widgets/attendance_flow_view_body.dart';

/// The four-step flow (Prepare, Location, Selfie, Review) for a check-in or
/// a check-out. The router opens it with the right [type].
class AttendanceFlowView extends StatelessWidget {
  const AttendanceFlowView({super.key, required this.type});

  final AttendanceType type;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AttendanceFlowCubit(type)),
        BlocProvider(create: (_) => LocationCubit(languageCode: language)),
      ],
      // Copies every location change (including the late address) into the
      // event, and clears it while the location is reloading or failed.
      child: BlocListener<LocationCubit, LocationState>(
        listener: (context, state) {
          context.read<AttendanceFlowCubit>().setLocation(
            state is LocationLoaded ? state.location : null,
          );
        },
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: SafeArea(child: AttendanceFlowViewBody()),
          ),
        ),
      ),
    );
  }
}
