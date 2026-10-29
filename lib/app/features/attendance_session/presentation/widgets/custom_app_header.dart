import 'package:efs_work_tracker/core/widgets/custom_back_button.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extensions.dart';

class CustomAppHeader extends StatelessWidget {
  const CustomAppHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomBackButton(),
        // Long titles wrap instead of overflowing on narrow phones.
        Flexible(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium,
          ),
        ),
        trailing ?? SizedBox(),
      ],
    );
  }
}
