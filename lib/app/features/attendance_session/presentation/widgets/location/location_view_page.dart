import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../manager/attendance_flow_cubit/attendance_flow_cubit.dart';
import '../../manager/location_cubit/location_cubit.dart';
import '../step_header.dart';
import 'location_action_button.dart';
import 'location_card.dart';

class LocationViewPage extends StatefulWidget {
  const LocationViewPage({super.key});

  @override
  State<LocationViewPage> createState() => _LocationViewPageState();
}

class _LocationViewPageState extends State<LocationViewPage> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // Ask for the location once, when the page opens (not in build).
    context.read<LocationCubit>().ensureLocation();

    // When the user returns from the phone settings, try again.
    _lifecycleListener = AppLifecycleListener(
      onResume: () => context.read<LocationCubit>().retryAfterSettings(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 20,
        children: [
          StepHeader(
            icon: Icons.location_on_outlined,
            title: context.l10n.verifyYourLocation,
            subtitle: context.l10n.keepYourLocation,
          ),
          BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) => Column(
              spacing: 20,
              children: [
                LocationCard(state: state),
                LocationActionButton(
                  state: state,
                  // The location is already in the event (AttendanceFlowView
                  // copies it), so this only moves to the Selfie step.
                  onContinue: context.read<AttendanceFlowCubit>().next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
