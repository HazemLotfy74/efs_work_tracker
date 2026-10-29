import 'active_request_filter.dart';
import 'inactive_request_filter.dart';

import 'package:flutter/material.dart';

class AnimationSelectRequestFilter extends StatelessWidget {
  const AnimationSelectRequestFilter({
    super.key,
    required this.title,
    required this.isActive,
  });

  final String title;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: ActiveRequestFilter(title: title),
      secondChild: InactiveRequestFilter(title: title),
      crossFadeState: isActive
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      duration: Duration(milliseconds: 200),
      firstCurve: Curves.easeIn,
      secondCurve: Curves.easeOut,
    );
  }
}
