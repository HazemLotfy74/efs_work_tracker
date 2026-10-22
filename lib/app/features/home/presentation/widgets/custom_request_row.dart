import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';

class CustomRequestRow extends StatelessWidget {
  const CustomRequestRow({
    super.key,
    required this.child,
    required this.title,
    required this.subTitle,
  });
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
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(12.5),
          ),
          child: child,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.itemTitle),
            Text(
              subTitle,
              style: AppTextStyles.meta.copyWith(
                color: context.colors.onSurfaceVariant,
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
