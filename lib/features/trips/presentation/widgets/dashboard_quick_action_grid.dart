import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardQuickActionGrid extends StatelessWidget {
  final VoidCallback onUploadDocsTap;
  final VoidCallback onContactAdminTap;
  final VoidCallback onTripStatusTap;

  const DashboardQuickActionGrid({
    super.key,
    required this.onUploadDocsTap,
    required this.onContactAdminTap,
    required this.onTripStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textMedium,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 24) / 3;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionCard(
                  icon: Icons.upload_file_outlined,
                  label: 'Upload Docs',
                  width: cardWidth,
                  onTap: onUploadDocsTap,
                ),
                _buildQuickActionCard(
                  icon: Icons.headset_mic_outlined,
                  label: 'Contact',
                  width: cardWidth,
                  onTap: onContactAdminTap,
                ),
                _buildQuickActionCard(
                  icon: Icons.construction_outlined,
                  label: 'Trip Status',
                  width: cardWidth,
                  onTap: onTripStatusTap,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF0F2C59),
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2C59),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
