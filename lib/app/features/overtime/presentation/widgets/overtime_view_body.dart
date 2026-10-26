import 'package:efs_work_tracker/app/features/overtime/presentation/widgets/overtime_request_container.dart';
import 'package:efs_work_tracker/app/features/overtime/presentation/widgets/over_time_status_header_widget.dart';
import 'package:efs_work_tracker/app/features/overtime/presentation/widgets/overtime_filter_widget.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:efs_work_tracker/core/widgets/text_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../attendance_session/presentation/widgets/custom_app_header.dart';

class OvertimeViewBody extends StatefulWidget {
  const OvertimeViewBody({super.key});

  @override
  State<OvertimeViewBody> createState() => _OvertimeViewBodyState();
}

class _OvertimeViewBodyState extends State<OvertimeViewBody> {
  final ValueNotifier<int> isActive = ValueNotifier(0);

  @override
  void dispose() {
    isActive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
    slivers: [
      SliverToBoxAdapter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            CustomAppHeader(title: context.l10n.overTimeRequests,trailing: CustomContainer(onTap: () {
             context.push(AppRoutes.createOvertime);
            },borderWidth: 1, child: Icon(Icons.add,)),),
            OverTimeStatusHeaderWidget(),
            ValueListenableBuilder(
              valueListenable: isActive,
              builder: (context, value, child) {
                return OvertimeFilterWidget(
                  onTap: (int value) {
                    isActive.value = value;
                  },
                  currentIndex: isActive.value,
                );
              },
            ),
            Text(
              context.l10n.recentRequests,
              style: context.textTheme.bodyMedium!.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),

          ],
        ),
      ),
      SliverList.separated(
        separatorBuilder: (context, index) => SizedBox(height: 10,),
        itemBuilder: (context, index) => OverTimeRequestContainer(),
        itemCount: 10,
        addAutomaticKeepAlives: true,
      ),
      SliverToBoxAdapter(
        child: SizedBox(height: 20,),
      ),
      SliverToBoxAdapter(
        child: AppPrimaryButton(onPressed: () {

        },child:TextIconWidget(txt: context.l10n.createOverTimeRequest, icon: Icons.add, style: context.textTheme.bodyMedium!.copyWith(
          color: context.colors.surface,
          fontWeight: FontWeight.w800,
        ), iconColor: context.colors.surface, iconSize: 15)
          ,

        ),
      )
    ],
        );


  }
}
