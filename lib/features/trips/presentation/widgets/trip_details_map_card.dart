import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../../../../core/theme/app_colors.dart';
import 'live_tracking_map.dart';

class TripDetailsMapCard extends StatelessWidget {
  final String fromLocation;
  final String toLocation;
  final LatLng? driverPosition;
  final double progress;
  final bool isTripInProgress;
  final String speedText;
  final String? statusMessage;
  final double height;

  const TripDetailsMapCard({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    this.driverPosition,
    this.progress = 0.08,
    this.isTripInProgress = false,
    this.speedText = '62 km/h',
    this.statusMessage,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
          // Live Google Map Widget with real location data & pins
          Positioned.fill(
            child: LiveTrackingMap(
              driverPosition: driverPosition,
              pickupLabel: fromLocation,
              dropLabel: toLocation,
              isLive: isTripInProgress,
              statusMessage: statusMessage,
              borderRadius: BorderRadius.circular(24),
            ),
          ),

          // Active GPS & speed overlays
          if (isTripInProgress) ...[
            // GPS Active Badge
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withAlpha(210),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(38)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'GPS ACTIVE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Speed indicator badge
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withAlpha(210),
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
                    const SizedBox(width: 6),
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
