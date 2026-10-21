import 'package:efs_work_tracker/app/features/home/presentation/widgets/attendance_event_widget.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/attendance_status_details_container.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/no_chekout_record_warning_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/custom_container.dart';
import 'custom_work_summary_widget.dart';

class AttendanceDetailsViewBody extends StatelessWidget {
  const AttendanceDetailsViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 20,
        children: [
          customAppBar(
            context: context,
            title: context.l10n.attendanceDetails,
            leading: CustomContainer(
              onTap: () {
                context.pop();
              },
              horizontalPadding: 5,
              verticalPadding: 5,
              borderWidth: 1,
              borderRadius: 13,
              child: Icon(Icons.arrow_back_ios_new),
            ),
          ),
          AttendanceStatusDetailsContainer(),
          NoChekoutRecordWarningWidget(),
          CustomContainer(
            borderWidth: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  context.l10n.workSummary,
                  style: TextTheme.of(context).bodyLarge!
                      .copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = 10.0;
                    final itemWidth = (constraints.maxWidth - spacing) / 2;
                    return CustomWorkSummaryWidget(
                      spacing: spacing,
                      itemWidth: itemWidth,
                      containerColor: ColorScheme.of(context)
                          .onPrimaryContainer,
                    );
                  },
                ),
              ],
            ),
          ),
          AttendanceEventWidget(),
        ],
      ),
    );
  }
}
