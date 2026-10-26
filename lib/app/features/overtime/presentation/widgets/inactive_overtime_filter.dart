import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';

class InactiveOvertimeFilter extends StatelessWidget {
  const InactiveOvertimeFilter({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      borderWidth: 1,
      child: Text(
        title,
        style: context.textTheme.bodyMedium!.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
