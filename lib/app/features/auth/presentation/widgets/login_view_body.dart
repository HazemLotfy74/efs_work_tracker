import 'package:efs_work_tracker/app/features/auth/presentation/widgets/login_view_form_field.dart';
import 'package:efs_work_tracker/core/extensions/context_l10n.dart';
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
                context.l10n.attendanceMadeClear,
                style: TextTheme.of(context).bodyMedium!
                    .copyWith(fontWeight: FontWeight.w400, fontSize: 14, color: ColorScheme.of(context).onSurfaceVariant),
              ),
              LoginViewFormField(isObscure: _isObscure, checkBox: _checkBox),
            ],
          ),
        ),
      ),
    );
  }
}
