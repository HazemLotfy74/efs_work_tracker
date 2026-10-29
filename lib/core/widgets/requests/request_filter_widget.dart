import 'package:flutter/material.dart';

import '../../enums/request_status.dart';
import '../../extensions/context_l10n.dart';
import 'animation_select_request_filter.dart';

/// All / Approved / Pending / Rejected chips, for request lists.
class RequestFilterWidget extends StatelessWidget {
  const RequestFilterWidget({
    super.key,
    required this.onChanged,
    required this.selected,
  });

  /// `null` is "All".
  final RequestStatus? selected;
  final ValueChanged<RequestStatus?> onChanged;

  /// The status of each chip, in order.
  static const statuses = <RequestStatus?>[
    null,
    RequestStatus.approved,
    RequestStatus.pending,
    RequestStatus.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    final titles = getFilterTitles(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 10,
        children: List.generate(statuses.length, (index) {
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () => onChanged(statuses[index]),
            child: AnimationSelectRequestFilter(
              title: titles[index],
              isActive: statuses[index] == selected,
            ),
          );
        }),
      ),
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
