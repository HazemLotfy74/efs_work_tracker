import 'package:efs_work_tracker/core/functions/form_validator_functions.dart';
import 'package:efs_work_tracker/core/theme/app_text_styles.dart';
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/widgets/text_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/custom_logo_icon.dart';
import 'custom_text_form_field.dart';

class ForgotPasswordViewBody extends StatefulWidget {
  const ForgotPasswordViewBody({super.key});

  @override
  State<ForgotPasswordViewBody> createState() => _ForgotPasswordViewBodyState();
}

class _ForgotPasswordViewBodyState extends State<ForgotPasswordViewBody> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(gradient: context.appColors.brandGradient),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              const CustomLogoIcon(onBrandSurface: true),
              Text(
                context.l10n.secureAccess,
                style: AppTextStyles.lead.copyWith(
                  color: context.appColors.onBrandSurfaceMuted,
                ),
              ),
              CustomContainer(
                horizontalPadding: 20,
                verticalPadding: 20,
                borderWidth: 1,
                borderRadius: 28,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          context.pop();
                        },
                        child: TextIconWidget(
                          mainAxisAlignment: MainAxisAlignment.start,
                          txt: context.l10n.backToSignIn,
                          icon: Icons.arrow_back_ios_new,
                          style: AppTextStyles.captionStrong.copyWith(
                            color: context.colors.primary,
                          ),
                          iconColor: context.colors.primary,
                          iconSize: 15,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        context.l10n.accountRecovery,
                        style: AppTextStyles.overline.copyWith(
                          color: context.colors.primary,
                        ),
                      ),
                      Text(
                        context.l10n.resetPassword,
                        style: context.textTheme.headlineMedium,
                      ),
                      Text(
                        context.l10n.enterRecEmailToSendLink,
                        style: AppTextStyles.lead.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 20),
                      CustomTextFormField(
                        validator: (p0) {
                          return emailValidator(p0);
                        },
                        prefixIcon: const Icon(Icons.email_outlined),
                        hintTxt: context.l10n.workEmail,
                        obscureText: false,
                        label: context.l10n.workEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 20),
                      AppPrimaryButton(
                        onPressed: () {
                          // TODO: send the recovery link once the API exists.
                          _formKey.currentState!.validate();
                        },
                        child: Text(context.l10n.sendRecLink),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
