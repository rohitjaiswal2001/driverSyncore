import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'custom_map_widget.dart';

class TripDetailsMapCard extends StatelessWidget {
  final String fromLocation;
  final String toLocation;
  final double progress;
  final bool isTripInProgress;
  final String speedText;

  const TripDetailsMapCard({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    this.progress = 0.08,
    this.isTripInProgress = false,
    this.speedText = '62 km/h',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Custom Slate-900 Map Widget
          Positioned.fill(
            child: CustomMapWidget(
              fromLocation: fromLocation,
              toLocation: toLocation,
              progress: progress,
              isTripInProgress: isTripInProgress,
            ),
          ),

          // If trip is in progress, show active overlays
          if (isTripInProgress) ...[
            // GPS Badge
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withAlpha(204),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(38)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'GPS ACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Speed indicator
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withAlpha(204),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(38)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.speed_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      speedText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
