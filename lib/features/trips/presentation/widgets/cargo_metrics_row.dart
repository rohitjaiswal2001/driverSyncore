import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CargoMetricsRow extends StatelessWidget {
  final String cargoType;
  final String weight;
  final double? distanceKm;

  const CargoMetricsRow({
    super.key,
    required this.cargoType,
    required this.weight,
    this.distanceKm,
  });

  String _formatDistance(double km) {
    if (km >= 100) return '${km.round()} km';
    return '${km.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')} km';
  }

  @override
  Widget build(BuildContext context) {
    final hasDistance = distanceKm != null && distanceKm! > 0;

    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            label: 'CARGO TYPE',
            value: cargoType.isNotEmpty ? cargoType : 'Standard Cargo',
            icon: Icons.inventory_2_rounded,
            iconColor: AppColors.primary,
            bgTint: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            label: 'WEIGHT',
            value: weight.isNotEmpty ? weight : 'N/A',
            icon: Icons.scale_rounded,
            iconColor: AppColors.accentBlue,
            bgTint: AppColors.accentBlue.withValues(alpha: 0.1),
          ),
        ),
        if (hasDistance) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildInfoCard(
              label: 'DISTANCE',
              value: _formatDistance(distanceKm!),
              icon: Icons.straighten_rounded,
              iconColor: AppColors.accentGreen,
              bgTint: AppColors.accentGreen.withValues(alpha: 0.15),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgTint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMedium,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
