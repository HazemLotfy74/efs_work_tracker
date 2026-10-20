import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_request_row.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/not_checked_in_custom_container.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/today_over_view_container.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/user_header.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
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
              Text(
                context.l10n.todayOverview,
                style: TextTheme.of(context).titleSmall,
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  context.l10n.viewDetails,
                  style: TextTheme.of(context).bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorScheme.of(context).primary,
                  ),
                ),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 10.0;
              final itemWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  TodayOverViewContainer(
                    width: itemWidth,
                    label: context.l10n.recorded,
                    value: '-',
                  ),
                  TodayOverViewContainer(
                    width: itemWidth,
                    label: context.l10n.lateness,
                    value: '-',
                  ),
                  TodayOverViewContainer(
                    width: itemWidth,
                    label: context.l10n.earlyLeave,
                    value: '0m',
                  ),
                  TodayOverViewContainer(
                    width: itemWidth,
                    label: context.l10n.approvedOT,
                    value: '0m',
                  ),
                ],
              );
            },
          ),
          InkWell(
            onTap: () {},
            child: CustomContainer(
              containerWidth: double.infinity,
              borderWidth: 1,
              child: CustomRequestRow(title: context.l10n.needToWorkLater, subTitle: context.l10n.requestOverTime, child: Icon(Icons.access_time),),
            ),
          ),
          InkWell(
            onTap: () {},
            child: CustomContainer(
              containerWidth: double.infinity,
              borderWidth: 1,
              child: CustomRequestRow(title: context.l10n.needCash, subTitle: context.l10n.sendRequest, child: Icon(Icons.request_quote),),
            ),
          ),
        ],
      ),
    );
  }
}
