import 'package:efs_work_tracker/core/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';

/// Labelled text field. Fill, border and icon colors come from the theme's
/// `inputDecorationTheme`.
class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.hintTxt,
    this.prefixIcon,
    this.suffixIcon,
    required this.obscureText,
    this.validator,
    this.textEditingController,
    this.onChanged,
    this.keyboardType,
    required this.label,
  });

  final String hintTxt;
  final String label;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextEditingController? textEditingController;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.appColors.fieldLabelText,
          ),
        ),
        TextFormField(
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          controller: textEditingController,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            hintText: hintTxt,
          ),
        ),
      ],
    );
  }
}
