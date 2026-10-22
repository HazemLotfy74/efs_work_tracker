import 'package:flutter/material.dart';

import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';

class CustomContainer extends StatelessWidget {
  const CustomContainer({
    super.key,
    this.containerWidth,
    required this.borderWidth,
    this.borderColor,
    this.containerColor,
    this.borderRadius,
    this.horizontalPadding,
    this.verticalPadding,
    required this.child,
    this.containerHeight,
    this.onTap,
  });
  final double? containerWidth;
  final double? containerHeight;
  final double? borderWidth;
  final double? borderRadius;
  final double? horizontalPadding;
  final double? verticalPadding;
  final Color? borderColor;
  final Color? containerColor;
  final Widget child;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: containerWidth,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding ?? 10,
          vertical: verticalPadding ?? 10,
        ),
        decoration: BoxDecoration(
          color: containerColor ?? context.colors.surface,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          border: Border.all(
            color: borderColor ?? context.colors.outlineVariant,
            width: borderWidth ?? 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
