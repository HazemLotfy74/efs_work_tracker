import 'package:flutter/material.dart';

import '../../theme/theme_context_extensions.dart';
import '../../widgets/custom_container.dart';

class ActiveRequestFilter extends StatelessWidget {
  const ActiveRequestFilter({super.key, required this.title});

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
