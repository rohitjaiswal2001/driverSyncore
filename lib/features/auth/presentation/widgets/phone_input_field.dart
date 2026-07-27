import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;

  const PhoneInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Enter mobile number';
        }
        if (val.trim().length < 10) {
          return 'Enter 10-digit number';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Enter mobile number',
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.phone_outlined, color: AppColors.textMedium, size: 20),
              SizedBox(width: 6),
              Text(
                '+91',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textLight,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
