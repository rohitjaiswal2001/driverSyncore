import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A label–value row used inside the Customer Profile info card.
class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const ProfileInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
