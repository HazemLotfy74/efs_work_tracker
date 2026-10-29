import 'package:efs_work_tracker/app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/widgets/auth_failure_text.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:efs_work_tracker/app/features/auth/presentation/widgets/forgot_password_and_check_box_widget.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/functions/form_validator_functions.dart';
import 'package:efs_work_tracker/core/theme/app_text_styles.dart';
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/widgets/app_primary_button.dart';
import 'package:efs_work_tracker/core/widgets/custom_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // On success the router leaves this screen by itself.
  Future<void> _signIn() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<AuthCubit>().signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(error, context.l10n));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              textEditingController: _emailController,
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
                  textEditingController: _passwordController,
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
            if (_error != null) ...[
              SizedBox(height: 12),
              Text(
                _error!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            SizedBox(height: 20),
            AppPrimaryButton(
              onPressed: _isLoading ? null : _signIn,
              child: _isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(context.l10n.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
