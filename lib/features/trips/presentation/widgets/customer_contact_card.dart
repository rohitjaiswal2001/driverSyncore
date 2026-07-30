import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/top_snack_bar.dart';

class CustomerContactCard extends StatelessWidget {
  final String customerName;
  final String customerPhone;

  const CustomerContactCard({
    super.key,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.customerBg,
            radius: 22,
            child: const Icon(
              Icons.person_outline,
              color: AppColors.customerAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CUSTOMER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  customerPhone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          // Dialer Button
          InkWell(
            onTap: () async {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: customerPhone,
              );
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              } else if (context.mounted) {
                TopSnackBar.show(
                  context,
                  message: 'Could not launch dialer for this number',
                  backgroundColor: AppColors.danger,
                  icon: Icons.error_outline,
                );
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone,
                color: AppColors.accentGreen,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
