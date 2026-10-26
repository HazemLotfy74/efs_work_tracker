import 'package:efs_work_tracker/app/features/home/presentation/widgets/custom_status_container.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extensions.dart';

class CashRequestContainer extends StatelessWidget {
  const CashRequestContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      borderWidth: 1,
      child: Row(
        spacing: 5,
        children: [
          CustomContainer(
            containerColor: context.colors.secondaryContainer,
            borderWidth: 1,
            child: Text(
              "250 EGP",
              style: context.textTheme.bodyMedium!.copyWith(
                color: context.colors.onSecondaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Column(
            spacing: 5,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomStatusContainer(tone: StatusTone.warning, text: context.l10n.pendingApproval),
              Text("Reason for cash"),
              Text("Submitted At : ")
            ],
          )
        ],
      ),
    );
  }
}
