import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';

class ForgotPasswordAndCheckBoxWidget extends StatelessWidget {
  const new({super.key, required this._checkBox});

  final ValueNotifier<bool> _checkBox;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ValueListenableBuilder(
              valueListenable: _checkBox,
              builder: (context, value, child) {
                return Checkbox(
                  value: _checkBox.value,
                  onChanged: (value) {
                    _checkBox.value = !_checkBox.value;
                  },
                );
              },
            ),
            Text(
              context.l10n.rememberMe,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            context.push(AppRoutes.forgotPassword);
          },
          child: Text(
            context.l10n.forgotPassword,
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
