import 'package:efs_work_tracker/app/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/widgets/forgot_password_and_check_box_widget.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/functions/form_validator_functions.dart';
import 'package:efs_work_tracker/core/router/app_routes.dart';
import 'package:efs_work_tracker/core/theme/app_text_styles.dart';
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/widgets/app_primary_button.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginViewFormField extends StatefulWidget {
  const LoginViewFormField({
    super.key,
    required this._isObscure,
    required this._checkBox,
  });

  final ValueNotifier<bool> _isObscure;
  final ValueNotifier<bool> _checkBox;

  @override
  State<LoginViewFormField> createState() => _LoginViewFormFieldState();
}

class _LoginViewFormFieldState extends State<LoginViewFormField> {
  final _formKey = GlobalKey<FormState>();
  final autoValidateMode = AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      horizontalPadding: 20,
      verticalPadding: 20,
      borderWidth: 1,
      borderRadius: 28,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.welcomeBack,
              style: context.textTheme.headlineMedium,
            ),
            Text(
              context.l10n.signWithAccount,
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
            ValueListenableBuilder(
              valueListenable: widget._isObscure,
              builder: (context, value, child) {
                return CustomTextFormField(
                  validator: (p0) {
                    return passwordValidator(p0);
                  },
                  prefixIcon: const Icon(Icons.lock_outlined),
                  hintTxt: context.l10n.password,
                  obscureText: widget._isObscure.value,
                  label: context.l10n.password,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: InkWell(
                    onTap: () {
                      widget._isObscure.value = !widget._isObscure.value;
                    },
                    child: Icon(
                      widget._isObscure.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            ForgotPasswordAndCheckBoxWidget(checkBox: widget._checkBox),
            SizedBox(height: 20),
            AppPrimaryButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.push(AppRoutes.home);
                } else {}
              },
              child: Text(context.l10n.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
