import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/text_icon_widget.dart';
import '../../../attendance_session/presentation/widgets/custom_app_header.dart';
import '../../../overtime/presentation/widgets/overtime_filter_widget.dart';
import 'cash_request_container.dart';

class AllCashesViewBody extends StatefulWidget {
  const AllCashesViewBody({super.key});

  @override
  State<AllCashesViewBody> createState() => _AllCashesViewBodyState();
}

class _AllCashesViewBodyState extends State<AllCashesViewBody> {

  final ValueNotifier<int> isActive = ValueNotifier(0);
@override
  void dispose() {
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
              CustomAppHeader(
                title: context.l10n.cashRequests,
                trailing: CustomContainer(
                  onTap: () {
                    context.push(AppRoutes.newCashRequest);
                  },
                  borderWidth: 1,
                  child: Icon(Icons.add),
                ),
              ),
              CustomContainer(
                containerColor: context.colors.onSurface,
                containerWidth: double.infinity,
                borderWidth: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 5,
                  children: [
                    Text(
                      context.l10n.pendingRequests,
                      style: context.textTheme.bodyMedium!.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      "250 Egp",
                      style: context.textTheme.bodyLarge!.copyWith(
                        color: context.colors.surface,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
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
          separatorBuilder: (context, index) => SizedBox(height: 10),
          itemBuilder: (context, index) => CashRequestContainer(),
          itemCount: 3,
          addAutomaticKeepAlives: true,
        ),
        SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: AppPrimaryButton(
            onPressed: () {
              context.push(AppRoutes.newCashRequest);
            },
            child: TextIconWidget(
              txt: context.l10n.newCashRequest,
              icon: Icons.add,
              style: context.textTheme.bodyMedium!.copyWith(
                color: context.colors.surface,
                fontWeight: FontWeight.w800,
              ),
              iconColor: context.colors.surface,
              iconSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
