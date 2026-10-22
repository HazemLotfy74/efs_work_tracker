import 'package:flutter/material.dart';

import '../../../../../../core/extensions/context_l10n.dart';
import '../../../../../../core/widgets/app_primary_button.dart';
import '../../../../../../core/widgets/custom_container.dart';
import '../step_header.dart';
import 'info_row.dart';

class PrepareViewPage extends StatelessWidget {
  const PrepareViewPage({super.key, required this.onContinue});

  /// Goes to the next step (Location).
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        StepHeader(
          icon: Icons.work_outline,
          title: context.l10n.readyToStart,
          subtitle: context.l10n.captureLocAndSelfie,
        ),
        CustomContainer(
          horizontalPadding: 20,
          verticalPadding: 20,
          borderWidth: 1,
          child: Column(
            children: [
              InfoRow(label: context.l10n.date, value: 'Wed , 14 may'),
              const Divider(height: 30),
              InfoRow(label: context.l10n.currentTime, value: '8:07 AM'),
              const Divider(height: 30),
              InfoRow(label: context.l10n.shift, value: '8:00 - 4:00'),
            ],
          ),
        ),
        const Spacer(),
        // A button without onPressed is disabled and drawn grey, which is why
        // the primary color did not show before.
        AppPrimaryButton(
          onPressed: onContinue,
          child: Text(context.l10n.continueTo),
        ),
      ],
    );
  }
}
