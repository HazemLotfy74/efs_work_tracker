import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../../../../../core/widgets/app_primary_button.dart';
import '../../manager/location_cubit/location_cubit.dart';

/// The page's main button. What it does depends on the state:
/// - loading  -> disabled (can't continue without a location)
/// - loaded   -> "Use this location", goes to the next step
/// - error    -> "Open settings" or "Try again"
class LocationActionButton extends StatelessWidget {
  const LocationActionButton({
    super.key,
    required this.state,
    required this.onContinue,
  });

  final LocationState state;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LocationCubit>();

    return switch (state) {
      LocationInitial() ||
      LocationLoading() => AppPrimaryButton(child: Text(l10n.useThisLoc)),
      LocationLoaded() => AppPrimaryButton(
        onPressed: onContinue,
        child: Text(l10n.useThisLoc),
      ),
      LocationError(:final failure) when failure.needsSettings =>
        AppPrimaryButton(
          onPressed: cubit.openSettings,
          child: Text(l10n.openSettings),
        ),
      LocationError() => AppPrimaryButton(
        onPressed: cubit.fetchLocation,
        child: Text(l10n.tryAgain),
      ),
    };
  }
}
