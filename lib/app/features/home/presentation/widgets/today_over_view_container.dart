import 'package:efs_work_tracker/core/constants/constants.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';

class TodayOverViewContainer extends StatelessWidget {
  const TodayOverViewContainer({super.key, required this.width, required this.label, required this.value});

  final double width;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 75.5
      ),
      child: CustomContainer(containerWidth: width, borderWidth: 1, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: getTextTheme(context).bodySmall!
                .copyWith(color: ColorScheme.of(context).onSurfaceVariant),
          ),
          Text(
            value,
            style: getTextTheme(context).bodyMedium!
                .copyWith(color: ColorScheme.of(context).onSurface,fontWeight: FontWeight.w800),
          ),
        ],
      ),),
    );
  }
}
