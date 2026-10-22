import 'package:efs_work_tracker/core/theme/app_text_styles.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme_colors.dart';
import '../../generated/assets.dart';

class CustomLogoIcon extends StatelessWidget {
  const CustomLogoIcon({super.key, this.txtColor, this.txtSize});

  final Color? txtColor;
  final double? txtSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Row(
      spacing: 10,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: Offset(0, 4),
                color: colorScheme.shadow.withAlpha(20),
              ),
            ],
          ),
          child: SvgPicture.asset(
            Assets.images.iconlogo.path,
            width: AppSizes.icon,
            height: AppSizes.icon,
          ),
        ),
        Text(
          "WorkTrack",
          style: AppTextStyles.brandWordmark.copyWith(
            color: txtColor??AppThemeColors.of(context).textHeading,
            fontSize: txtSize??16,
          ),
        ),
      ],
    );
  }
}
