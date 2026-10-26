import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';

class ActiveOvertimeFilter extends StatelessWidget {
  const ActiveOvertimeFilter({super.key, required this.title});

  final String title;
  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      containerColor: context.colors.onSurface,
      borderWidth: 1,
      child: Text(
        title,
        style: context.textTheme.bodyMedium!.copyWith(
          color: context.colors.surface,
        ),
      ),
    );
  }
}
