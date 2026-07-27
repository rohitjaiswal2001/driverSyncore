import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A quote summary card showing ID, route, price, and status badge.
/// Used in the Customer Home "Recent Quotes" section.
class QuoteListTile extends StatelessWidget {
  final String id;
  final String route;
  final String price;
  final String status;
  final VoidCallback? onTap;

  const QuoteListTile({
    super.key,
    required this.id,
    required this.route,
    required this.price,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAccepted = status.toUpperCase() == 'ACCEPTED';
    final badgeColor = isAccepted
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEF3C7);
    final badgeTextColor = isAccepted
        ? AppColors.accentGreen
        : AppColors.accentOrange;
    final iconColor = isAccepted
        ? AppColors.primary
        : AppColors.accentOrange;
    final iconBgColor = isAccepted
        ? AppColors.primaryLight
        : const Color(0xFFFEF3C7);
    final icon = isAccepted
        ? Icons.check_circle_outline
        : Icons.hourglass_empty_outlined;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  route,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),);
  }
}
