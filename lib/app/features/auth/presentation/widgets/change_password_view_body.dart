import 'package:efs_work_tracker/core/functions/form_validator_functions.dart';
import 'package:efs_work_tracker/core/theme/app_text_styles.dart';
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/widgets/text_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_l10n.dart';
import '../../../../../core/widgets/app_primary_button.dart';
import '../../../../../core/widgets/custom_container.dart';
import '../../../../../core/widgets/custom_logo_icon.dart';
import '../manager/auth_cubit/auth_cubit.dart';
import 'auth_failure_text.dart';
import 'custom_text_form_field.dart';

/// Shown after the first sign-in and after a recovery link, while
/// `must_change_password` is true. The router opens and leaves it.
class ChangePasswordViewBody extends StatefulWidget {
  const ChangePasswordViewBody({super.key});

  @override
  State<ChangePasswordViewBody> createState() => _ChangePasswordViewBodyState();
}

class _ChangePasswordViewBodyState extends State<ChangePasswordViewBody> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final ValueNotifier<bool> _isObscure = ValueNotifier(true);
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _isObscure.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<AuthCubit>().changePassword(_passwordController.text);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(error, context.l10n));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                  child: ValueListenableBuilder(
                    valueListenable: _isObscure,
                    builder: (context, isObscure, child) {
                      final visibilityToggle = InkWell(
                        onTap: () => _isObscure.value = !_isObscure.value,
                        child: Icon(
                          isObscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _isLoading
                                ? null
                                : () => context.read<AuthCubit>().signOut(),
                            child: TextIconWidget(
                              mainAxisAlignment: MainAxisAlignment.start,
                              txt: context.l10n.signOut,
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
                            context.l10n.accountSetup,
                            style: AppTextStyles.overline.copyWith(
                              color: context.colors.primary,
                            ),
                          ),
                          Text(
                            context.l10n.changePasswordTitle,
                            style: context.textTheme.headlineMedium,
                          ),
                          Text(
                            context.l10n.changePasswordSubtitle,
                            style: AppTextStyles.lead.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 20),
                          CustomTextFormField(
                            textEditingController: _passwordController,
                            validator: newPasswordValidator,
                            prefixIcon: const Icon(Icons.lock_outlined),
                            hintTxt: context.l10n.passwordRules,
                            obscureText: isObscure,
                            label: context.l10n.newPassword,
                            keyboardType: TextInputType.visiblePassword,
                            suffixIcon: visibilityToggle,
                          ),
                          SizedBox(height: 20),
                          CustomTextFormField(
                            textEditingController: _confirmController,
                            validator: (value) => confirmPasswordValidator(
                              value,
                              _passwordController.text,
                            ),
                            prefixIcon: const Icon(Icons.lock_outlined),
                            hintTxt: context.l10n.confirmNewPassword,
                            obscureText: isObscure,
                            label: context.l10n.confirmNewPassword,
                            keyboardType: TextInputType.visiblePassword,
                            suffixIcon: visibilityToggle,
                          ),
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
                            onPressed: _isLoading ? null : _save,
                            child: _isLoading
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(context.l10n.savePassword),
                          ),
                        ],
                      );
                    },
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
