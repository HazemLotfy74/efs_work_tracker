import 'package:flutter/material.dart';

import 'location/location_view_page.dart';
import 'prepare/prepare_view_page.dart';
import 'review/review_page_view.dart';
import 'selfie_page_view.dart';

/// The four check-in steps. Swiping is off: pages change only through
/// `CheckInCubit`, which allows moving on once the current step is captured.
class AttendanceSessionPageView extends StatelessWidget {
  const AttendanceSessionPageView({super.key, required this.pageController});

  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            PrepareViewPage(),
            LocationViewPage(),
            SelfiePageView(),
            ReviewPageView(),
          ],
        ),
      ),
    );
  }
}
