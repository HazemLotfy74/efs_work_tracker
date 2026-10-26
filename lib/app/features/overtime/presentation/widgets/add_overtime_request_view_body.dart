import 'package:efs_work_tracker/app/features/attendance_session/presentation/widgets/custom_app_header.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:efs_work_tracker/app/features/overtime/presentation/widgets/overtime_time_selection.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/widgets/app_primary_button.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extensions.dart';

class AddOvertimeRequestViewBody extends StatelessWidget {
  const AddOvertimeRequestViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          CustomAppHeader(title: context.l10n.requestOverTimePage),
          CustomContainer(
            containerColor: context.colors.primaryContainer,
            borderWidth: 1,
            child: Row(
              spacing: 5,
              children: [
                Icon(Icons.access_time_rounded, color: context.colors.primary),
                Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.approvalRequired,
                      style: context.textTheme.bodyMedium!.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                    Text(
                      context.l10n.workingAfter4,
                      style: context.textTheme.bodyMedium!.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            context.l10n.requestedScheduled,
            style: context.textTheme.bodyLarge!.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          OvertimeTimeSection(),
          CustomContainer(
            containerColor: context.colors.primaryContainer,
            borderWidth: 1,
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, color: context.colors.primary),
                Text(
                  context.l10n.requestedDuration,
                  style: context.textTheme.bodyMedium!.copyWith(
                    color: context.colors.primary,
                  ),
                ),
                Spacer(),
                Text(
                  "2H 0M",
                  style: context.textTheme.bodyMedium!.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
              ],
            ),
          ),
          CustomTextFormField(
            hintTxt: context.l10n.reasonForOverTime,
            obscureText: false,
            label: context.l10n.reasonForOverTime,
          ),
          CustomContainer(
            borderWidth: 1,
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.requestSummary),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(context.l10n.date), Text("14 may")],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(context.l10n.date), Text("14 may")],
                ),
              ],
            ),
          ),
          AppPrimaryButton(
            child: Text(context.l10n.request),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
