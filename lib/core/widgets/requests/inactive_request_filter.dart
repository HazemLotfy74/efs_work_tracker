import 'package:flutter/material.dart';

import '../../theme/theme_context_extensions.dart';
import '../../widgets/custom_container.dart';

class InactiveRequestFilter extends StatelessWidget {
  const InactiveRequestFilter({super.key, required this.title});

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
