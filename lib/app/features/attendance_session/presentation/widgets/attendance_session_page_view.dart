import 'package:flutter/material.dart';

import 'location/location_view_page.dart';
import 'prepare/prepare_view_page.dart';
import 'review_page_view.dart';
import 'selfie_page_view.dart';

class AttendanceSessionPageView extends StatelessWidget {
  const AttendanceSessionPageView({super.key, required this.pageController});

  final PageController pageController;

  void _nextPage() {
    pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            PrepareViewPage(onContinue: _nextPage),
            LocationViewPage(onContinue: _nextPage),
            const SelfiePageView(),
            const ReviewPageView(),
          ],
        ),
      ),
    );
  }
}
