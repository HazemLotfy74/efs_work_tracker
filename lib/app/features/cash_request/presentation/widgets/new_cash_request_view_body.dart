import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extensions.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../attendance_session/presentation/widgets/custom_app_header.dart';
import '../../../auth/presentation/widgets/custom_text_form_field.dart';

class NewCashRequestViewBody extends StatelessWidget {
  const NewCashRequestViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          CustomAppHeader(title: context.l10n.cashRequests),
          CustomContainer(
            containerColor: context.colors.primaryContainer,
            borderWidth: 1,
            child: Row(
              spacing: 5,
              children: [
                Icon(Icons.privacy_tip, color: context.colors.primary),
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
                      context.l10n.submittingApproval,
                      style: context.textTheme.bodyMedium!.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          CustomTextFormField(
            prefixIcon: Icon(Icons.monetization_on_outlined),
            hintTxt: context.l10n.requestAmount,
            obscureText: false,
            label: context.l10n.requestAmount,
            keyboardType: TextInputType.number,
          ),

          CustomTextFormField(
            hintTxt: context.l10n.reasonForRequest,
            obscureText: false,
            label: context.l10n.reasonForRequest,
          ),
          CustomContainer(
            borderWidth: 1,
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.requestSummary,style: context.textTheme.bodyLarge!.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w800,

                ),),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(context.l10n.employee), Text("Mohamed")],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(context.l10n.amount), Text("250 Egp")],
                ),
              ],
            ),
          ),
          AppPrimaryButton(
            child: Text(context.l10n.sendToAdmin),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
