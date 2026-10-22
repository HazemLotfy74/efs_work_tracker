import 'package:efs_work_tracker/app/features/attendance_session/presentation/manager/location_cubit/location_cubit.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/check_in_view_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CheckInView extends StatelessWidget {
  const CheckInView({super.key});

  @override
  Widget build(BuildContext context) {
    // Read in build, not inside `create`: `create` runs once (lazily, on the
    // first read), so it must not subscribe to inherited widgets.
    final language = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) => LocationCubit(languageCode: language),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: SafeArea(child: CheckInViewBody()),
        ),
      ),
    );
  }
}
