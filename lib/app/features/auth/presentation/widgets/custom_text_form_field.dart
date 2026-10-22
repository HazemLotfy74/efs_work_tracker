import 'package:efs_work_tracker/core/utils/app_dimensions.dart';
import 'package:flutter/material.dart';

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
    this.keyboardType, required this.label,
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
        Text(label,style: TextTheme.of(context).bodyMedium!.copyWith(color: ColorScheme.of(context).onSurfaceVariant,fontWeight: FontWeight.w700),),
        TextFormField(
          cursorColor: ColorScheme.of(context).primary,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          controller: textEditingController,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            hintText: hintTxt,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: ColorScheme.of(context).outlineVariant,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.r14),
            ),
            filled: true,
            fillColor: ColorScheme.of(context).surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r14),
              borderSide: BorderSide(
                color: ColorScheme.of(context).outlineVariant,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
