import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final T? value;
  final String hintText;
  final IconData? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final double menuMaxHeight;

  const CustomDropdownField({
    super.key,
    this.value,
    required this.hintText,
    this.prefixIcon,
    required this.items,
    this.onChanged,
    this.validator,
    this.menuMaxHeight = 350,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      alignedDropdown: true,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        hint: Text(hintText),
        dropdownColor: Colors.white,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textMedium,
        ),

        borderRadius: BorderRadius.circular(12),
        menuMaxHeight: menuMaxHeight,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: AppColors.textMedium, size: 20)
              : null,
        ),
      ),
    );
  }
}
