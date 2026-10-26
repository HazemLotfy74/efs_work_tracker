import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_l10n.dart';
import 'animation_select_overtime_filter.dart';

class OvertimeFilterWidget extends StatelessWidget {
  const OvertimeFilterWidget({super.key, required this.onTap, required this.currentIndex});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
     spacing: 10,
      children: List.generate(getFilterTitles(context).length, (index) {
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent
        ,onTap: () {
          onTap(index);
        },child: AnimationSelectOvertimeFilter(title: getFilterTitles(context)[index], isActive: index == currentIndex,));
      },),
    );
  }

  List<String> getFilterTitles(BuildContext context) {
    return [
      context.l10n.all,
      context.l10n.approved,
      context.l10n.pendingApproval,
      context.l10n.rejected,
    ];
  }
}
