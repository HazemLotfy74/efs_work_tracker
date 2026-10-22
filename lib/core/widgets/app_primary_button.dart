import 'package:flutter/material.dart';

import '../theme/theme_context_extensions.dart';

/// Full-width green button used for the main action on a screen.
///
/// Shape and label style come from the theme's `filledButtonTheme`.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.bgColor,
  });

  final Widget child;
  final VoidCallback? onPressed;

  /// Defaults to the theme's primary color.
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.24),
                  offset: const Offset(0, 10),
                  blurRadius: 12,
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: onPressed,
          style: bgColor == null
              ? null
              : FilledButton.styleFrom(backgroundColor: bgColor),
          child: child,
        ),
      ),
    );
  }
}
