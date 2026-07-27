import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LabeledFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final double bottomSpacing;

  const LabeledFormField({
    super.key,
    required this.label,
    required this.child,
    this.bottomSpacing = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        child,
        SizedBox(height: bottomSpacing),
      ],
    );
  }
}
