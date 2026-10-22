import 'package:efs_work_tracker/app/features/auth/presentation/widgets/login_view_form_field.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
import 'package:efs_work_tracker/core/theme/app_text_styles.dart';
import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:efs_work_tracker/core/widgets/custom_logo_icon.dart';
import 'package:flutter/material.dart';

class LoginViewBody extends StatefulWidget {
  const LoginViewBody({super.key});

  @override
  State<LoginViewBody> createState() => _LoginViewBodyState();
}

class _LoginViewBodyState extends State<LoginViewBody> {
  final ValueNotifier<bool> _isObscure = ValueNotifier(true);
  final ValueNotifier<bool> _checkBox = ValueNotifier(false);

  @override
  void dispose() {
    _isObscure.dispose();
    super.dispose();
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
                context.l10n.attendanceMadeClear,
                style: AppTextStyles.lead.copyWith(
                  color: context.appColors.onBrandSurfaceMuted,
                ),
              ),
              LoginViewFormField(isObscure: _isObscure, checkBox: _checkBox),
            ],
          ),
        ),
      ),
    );
  }
}
