import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';

import '../../../../../core/extensions/date_time_format.dart';
import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/requests/request_status_badge.dart';
import '../../domain/entities/expense_advance_request_entity.dart';
import 'money_text.dart';

class CashRequestContainer extends StatelessWidget {
  const CashRequestContainer({super.key, required this.request});

  final ExpenseAdvanceRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final reviewNote = request.reviewNote;
    return CustomContainer(
      borderWidth: 1,
      child: Row(
        spacing: 10,
        children: [
          CustomContainer(
            containerColor: context.colors.secondaryContainer,
            borderWidth: 1,
            child: Text(
              formatMoney(context, request.amount, request.currency),
              style: context.textTheme.bodyMedium!.copyWith(
                color: context.colors.onSecondaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Column(
              spacing: 5,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RequestStatusBadge(status: request.status),
                Text(
                  request.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${context.l10n.submittedAt}: '
                  '${request.createdAt.formatShortDate(context)}',
                  style: context.textTheme.bodySmall!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                if (reviewNote != null && reviewNote.isNotEmpty)
                  Text(
                    '${context.l10n.reviewNote}: $reviewNote',
                    style: context.textTheme.bodySmall!.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
