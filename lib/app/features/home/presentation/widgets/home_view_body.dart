import 'package:efs_work_tracker/app/features/home/presentation/widgets/not_checked_in_custom_container.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/today_over_view_container.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/user_header.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/custom_logo_icon.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const CustomLogoIcon(),
          SizedBox(height: AppSpacing.lg),
          UserHeader(),
          NotCheckedInCustomContainer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Overview", style: TextTheme.of(context).titleSmall),
              TextButton(
                onPressed: () {},
                child: Text(
                  "View Details",
                  style: TextTheme.of(context).bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorScheme.of(context).primary,
                  ),
                ),
              ),
            ],
          ),
          LayoutBuilder(builder: (context, constraints) {
            final spacing = 10.0;
            final itemWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(spacing: spacing,runSpacing: spacing,children: [
              TodayOverViewContainer(width: itemWidth, label: 'Recorded', value: '-',),
              TodayOverViewContainer(width: itemWidth, label: 'Lateness', value: '-',),
              TodayOverViewContainer(width: itemWidth, label: 'Early leave', value: '0m',),
              TodayOverViewContainer(width: itemWidth, label: 'Approved OT', value: '0m',),
            ]);
          },)
        ],
      ),
    );
  }
}
