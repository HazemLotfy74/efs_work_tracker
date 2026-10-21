import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_request_row.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_work_summary_widget.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/not_checked_in_custom_container.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/user_header.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/router/app_routes.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                onPressed: () {
                  context.push(AppRoutes.attendanceDetails);
                },
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
              return CustomWorkSummaryWidget(
                spacing: spacing,
                itemWidth: itemWidth,
              );
            },
          ),
          InkWell(
            onTap: () {},
            child: CustomContainer(
              containerWidth: double.infinity,
              borderWidth: 1,
              child: CustomRequestRow(
                title: context.l10n.needToWorkLater,
                subTitle: context.l10n.requestOverTime,
                child: Icon(Icons.access_time,color: ColorScheme.of(context).primary,),
              ),
            ),
          ),
          InkWell(
            onTap: () {},
            child: CustomContainer(
              containerWidth: double.infinity,
              borderWidth: 1,
              child: CustomRequestRow(
                title: context.l10n.needCash,
                subTitle: context.l10n.sendRequest,
                child: Icon(Icons.request_quote,color: ColorScheme.of(context).primary,),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
