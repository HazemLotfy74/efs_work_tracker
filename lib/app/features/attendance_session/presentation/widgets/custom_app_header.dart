import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/widgets/custom_back_button.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extensions.dart';

class CustomAppHeader extends StatelessWidget {
  const CustomAppHeader({super.key, this.trailing});

  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomBackButton(),
        Text(context.l10n.checkInPage, style: context.textTheme.titleMedium),
        trailing ?? SizedBox(),
      ],
    );
  }
}
