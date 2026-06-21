import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: AppColors.primary,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.subHeading.copyWith(
          color: const Color(0x99B8B8B8),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.primary,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.2,
          ),
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),
    );
  }
}