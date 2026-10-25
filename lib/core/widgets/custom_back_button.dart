import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'custom_container.dart';

class CustomBackButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      onTap: () {
        context.pop();
      },
      horizontalPadding: 10,
      verticalPadding: 10,
      borderWidth: 1,
      borderRadius: 13,
      child: Icon(Icons.arrow_back_ios_new, color: context.colors.onSurface),
    );
  }
}
