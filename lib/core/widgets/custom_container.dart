import 'package:flutter/material.dart';

class CustomContainer extends StatelessWidget {
  const CustomContainer({super.key, required this.containerWidth, required this.borderWidth, this.borderColor, this.containerColor, this.borderRadius, this.horizontalPadding, this.verticalPadding, required this.child});
final double containerWidth;
final double? borderWidth;
final double? borderRadius;
final double? horizontalPadding;
final double? verticalPadding;
final Color? borderColor;
final Color? containerColor;
final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: containerWidth,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding??10, vertical: verticalPadding??10),
      decoration: BoxDecoration(
        color: containerColor??ColorScheme.of(context).surface,
        borderRadius: BorderRadius.circular(borderRadius??12),
        border: Border.all(
          color: borderColor??ColorScheme.of(context).outlineVariant,
          width: borderWidth??1,
        ),
      ),
      child: child,
    );
  }
}
