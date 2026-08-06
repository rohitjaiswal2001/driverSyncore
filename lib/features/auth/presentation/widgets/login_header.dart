import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Logo & Tagline
        Center(
          child: Column(
            children: [
              Image.asset(
                AppAssets.logo,
                height: 55,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.hexagon_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'globelink',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Smart Logistics, Simplified.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Welcome Header
        Center(
          child: Column(
            children: [
              const Text(
                'Login to your account to continue',
                style: TextStyle(fontSize: 14, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
