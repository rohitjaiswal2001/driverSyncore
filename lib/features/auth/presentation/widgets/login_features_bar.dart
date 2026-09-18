import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive.dart';

class LoginFeaturesBar extends StatelessWidget {
  const LoginFeaturesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border.all(color: AppColors.border.withAlpha(128), width: 1),
      ),
      // The white sheet stays full-bleed so it still reads as the bottom of
      // the screen on an iPad, but the four items are centred within it —
      // spread across 1300pt they would sit nowhere near each other.
      child: AdaptiveContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFeatureItem(
              icon: Icons.verified_user_outlined,
              title: 'Trusted &\nVerified',
            ),
            _buildFeatureItem(
              icon: Icons.history_toggle_off_rounded,
              title: 'On-Time\nDelivery',
            ),
            _buildFeatureItem(
              icon: Icons.pin_drop_outlined,
              title: 'Live Tracking\n24×7',
            ),
            _buildFeatureItem(
              icon: Icons.headset_mic_outlined,
              title: '24/7 Customer\nSupport',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String title}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
