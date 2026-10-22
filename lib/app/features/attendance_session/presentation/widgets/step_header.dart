import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';

/// Icon, title and subtitle at the top of each check-in step.
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        CustomContainer(
          borderRadius: 24,
          horizontalPadding: 20,
          verticalPadding: 20,
          borderWidth: 0,
          containerColor: context.colors.primaryContainer,
          child: Icon(icon, color: context.colors.primary),
        ),
        Text(title, style: context.textTheme.titleLarge),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall,
        ),
      ],
    );
  }
}
