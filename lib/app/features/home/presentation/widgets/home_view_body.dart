import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_request_row.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_work_summary_widget.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/today_attendance_card.dart';
import 'package:efs_work_tracker/app/features/home/presentation/widgets/user_header.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/router/app_routes.dart';
import 'package:efs_work_tracker/core/theme/app_text_styles.dart';
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/manager/clock_cubit.dart';
import '../../../attendance_session/presentation/manager/attendance_session_cubit/attendance_session_cubit.dart';

import '../../../../../core/widgets/custom_logo_icon.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    final now = context.watch<ClockCubit>().state;
    final attendance = context.watch<AttendanceSessionCubit>().state;
    final today = attendance is AttendanceSessionLoaded
        ? attendance.session
        : null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const CustomLogoIcon(),
          SizedBox(height: AppSpacing.lg),
          UserHeader(),
          const TodayAttendanceCard(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.todayOverview,
                style: context.textTheme.titleSmall,
              ),
              if (today != null)
                TextButton(
                  onPressed: () {
                    context.push(AppRoutes.attendanceDetailsOf(today.id));
                  },
                  child: Text(
                    context.l10n.viewDetails,
                    style: AppTextStyles.captionStrong.copyWith(
                      color: context.colors.primary,
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
                session: today,
                now: now,
              );
            },
          ),
          // Overtime needs no request: every minute past 8 worked hours is
          // counted automatically (see WorkDuration).
          InkWell(
            onTap: () {
              context.push(AppRoutes.cashRequest);
            },
            child: CustomContainer(
              containerWidth: double.infinity,
              borderWidth: 1,
              child: CustomRequestRow(
                title: context.l10n.needCash,
                subTitle: context.l10n.sendRequest,
                child: Icon(Icons.request_quote, color: context.colors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
