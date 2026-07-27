import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onFieldSubmitted;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  const PasswordInputField({
    super.key,
    required this.controller,
    this.onFieldSubmitted,
    this.hintText = 'Enter password',
    this.prefixIcon = Icons.lock_open_rounded,
    this.validator,
    this.textInputAction = TextInputAction.done,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscurePassword = true;

  String? _defaultValidator(String? val) {
    if (val == null || val.isEmpty) {
      return 'Enter your password';
    }
    if (val.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscurePassword,
      textInputAction: widget.textInputAction,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      validator: widget.validator ?? _defaultValidator,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(
          widget.prefixIcon,
          color: AppColors.textMedium,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textLight,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      onFieldSubmitted: (_) => widget.onFieldSubmitted?.call(),
    );
  }
}
