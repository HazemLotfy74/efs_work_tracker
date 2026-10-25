import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/attendance_steps.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/custom_app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../manager/attendance_flow_cubit/attendance_flow_cubit.dart';
import 'attendance_session_page_view.dart';
import 'attendance_type_text.dart';

class AttendanceFlowViewBody extends StatefulWidget {
  const AttendanceFlowViewBody({super.key});

  @override
  State<AttendanceFlowViewBody> createState() => _AttendanceFlowViewBodyState();
}

class _AttendanceFlowViewBodyState extends State<AttendanceFlowViewBody> {
  final pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The cubit owns the current step; the PageView just follows it.
    return BlocConsumer<AttendanceFlowCubit, AttendanceFlowState>(
      listenWhen: (previous, current) =>
          previous.currentStep != current.currentStep,
      listener: (context, state) {
        pageController.animateToPage(
          state.currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      buildWhen: (previous, current) =>
          previous.currentStep != current.currentStep ||
          previous.event.unlockedStep != current.event.unlockedStep,
      builder: (context, state) {
        return Column(
          spacing: 20,
          children: [
            CustomAppHeader(
              title: state.type.title(context.l10n),
              trailing: Text(
                context.l10n.stepOf(state.currentStep + 1, 4),
                style: AppTextStyles.captionStrong.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            AttendanceSteps(
              currentPage: state.currentStep,
              unlockedStep: state.event.unlockedStep,
              onTap: context.read<AttendanceFlowCubit>().goToStep,
            ),
            AttendanceSessionPageView(pageController: pageController),
          ],
        );
      },
    );
  }
}
