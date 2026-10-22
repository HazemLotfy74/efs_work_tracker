import 'package:efs_work_tracker/core/functions/form_validator_functions.dart';
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
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin:  Alignment.topCenter,
              end: Alignment.bottomCenter
              ,colors: [
            Color(0xff06251E),
            Color(0xff103B31),
            Color(0xff155843),
          ])
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              CustomLogoIcon(
                txtColor: ColorScheme.of(context).surface,
                txtSize: 22,
              ),
              Text(
                context.l10n.secureAccess,
                style: TextTheme.of(context).bodyMedium!
                    .copyWith(fontWeight: FontWeight.w400, fontSize: 14, color: ColorScheme.of(context).onSurfaceVariant),
              ),
              CustomContainer(
                horizontalPadding: 20,
                verticalPadding: 20,
                borderWidth: 1,
                borderRadius: 28,
                containerColor: ColorScheme.of(context).surface,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          context.pop();
                        },
                        child: TextIconWidget(mainAxisAlignment: MainAxisAlignment.start,txt: context.l10n.backToSignIn, icon: Icons.arrow_back_ios_new, style: TextTheme.of(context).bodyMedium!.copyWith(
                          color: ColorScheme.of(context).primary
                        ), iconColor: ColorScheme.of(context).primary, iconSize: 15),
                      ),
                      SizedBox(height: 20),
                      Text(
                        context.l10n.accountRecovery,
                        style: TextTheme.of(context).bodySmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ColorScheme.of(context).primary,
                        ),
                      ),
                      Text(
                        context.l10n.resetPassword,
                        style: TextTheme.of(context).bodyMedium!
                            .copyWith(fontWeight: FontWeight.w800, fontSize: 26),
                      ),
                      Text(
                        context.l10n.enterRecEmailToSendLink,
                        style: TextTheme.of(context).bodyMedium!
                            .copyWith(fontWeight: FontWeight.w400, fontSize: 14),
                      ),
                      SizedBox(height: 20),
                      CustomTextFormField(
                        validator: (p0) {
                          return emailValidator(p0);
                        },
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: ColorScheme.of(context).onSecondaryFixedVariant,
                        ),
                        hintTxt: context.l10n.workEmail,
                        obscureText: false,
                        label: context.l10n.workEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 20),
                      AppPrimaryButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            print("done");
                          }
                          else{
                            print("not done");
                          }
                        },
                        child: Text(
                          context.l10n.sendRecLink,
                          style: TextTheme.of(context).bodyMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: ColorScheme.of(context).surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
