import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DriverGreetingHeader extends StatelessWidget {
  final String salutation;
  final String name;

  const DriverGreetingHeader({
    super.key,
    required this.salutation,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Driver' : name.trim();
    final formattedName = displayName.endsWith('!')
        ? displayName
        : '$displayName!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          salutation,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.navy,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Let's get your shipments moving.",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }
}
