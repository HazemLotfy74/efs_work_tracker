
import 'package:flutter/material.dart';

class CustomRequestRow extends StatelessWidget {
  const CustomRequestRow({super.key, required this.child, required this.title, required this.subTitle});
  final Widget child;
  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          decoration: BoxDecoration(
            color: ColorScheme.of(context).onPrimary,
            borderRadius: BorderRadius.circular(12.5),
          ),
          child: child,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextTheme.of(context).bodySmall!
                  .copyWith(color: ColorScheme.of(context).onSurface),
            ),
            Text(
              subTitle,
              style: TextTheme.of(context).bodySmall!.copyWith(
                color: ColorScheme.of(context).onSurfaceVariant,
                fontSize: 8,
              ),
            ),
          ],
        ),
        Spacer(),
        Icon(Icons.arrow_forward_ios_sharp),
      ],
    );
  }
}
