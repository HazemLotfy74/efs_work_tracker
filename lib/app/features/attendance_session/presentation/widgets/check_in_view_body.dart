import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/attendance_steps.dart';
import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/custom_app_header.dart';
import 'package:flutter/material.dart';

import 'attendance_session_page_view.dart';

class CheckInViewBody extends StatefulWidget {
  const CheckInViewBody({super.key});

  @override
  State<CheckInViewBody> createState() => _CheckInViewBodyState();
}

class _CheckInViewBodyState extends State<CheckInViewBody> {
  late PageController pageController;
  ValueNotifier<int> currentPage = ValueNotifier(0);

  @override
  void initState() {
    pageController = PageController();
    pageController.addListener(() {
      currentPage.value = pageController.page!.toInt();
    });
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        CustomAppHeader(),
        ValueListenableBuilder(
          valueListenable: currentPage,
          builder: (context, value, child) {
            return AttendanceSteps(
              currentPage: currentPage.value,
              onTap: (value) {
                pageController.animateToPage(
                  value,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            );
          },
        ),
        AttendanceSessionPageView(pageController: pageController),
      ],
    );
  }
}
