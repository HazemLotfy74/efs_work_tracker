import 'package:flutter/material.dart';

class TextIconWidget extends StatelessWidget {
  const TextIconWidget({
    super.key,
    required this.txt,
    required this.icon,
    required this.style,
    required this.iconColor,
    required this.iconSize,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
  });

  final String txt;
  final TextStyle style;
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.center,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      spacing: 10,
      children: [
        Icon(icon, color: iconColor, size: iconSize),
        Text(txt, style: style),
      ],
    );
  }
}
