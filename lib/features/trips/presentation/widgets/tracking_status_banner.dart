import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/tracking_status.dart';

/// Explains the shipment's live-tracking session state when it isn't
/// self-evident from the map (not started yet, finished, or failed).
///
/// Renders nothing while tracking is actively running (SHIPMENT_START /
/// ONGOING) - the map's own "GPS LIVE" badge already communicates that.
class TrackingStatusBanner extends StatelessWidget {
  final TrackingStatus? status;

  const TrackingStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status != null && status!.isLiveTrackingEligible) {
      return const SizedBox.shrink();
    }

    final _BannerContent content = switch (status?.code) {
      TrackingStatus.codeNotStarted => const _BannerContent(
          icon: Icons.hourglass_empty_rounded,
          color: AppColors.textMedium,
          background: Color(0xFFF1F5F9),
          title: 'Tracking not started',
          message:
              'Live location tracking will begin automatically once you start this shipment.',
        ),
      TrackingStatus.codeShippingDone => const _BannerContent(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.accentBlue,
          background: AppColors.infoBg,
          title: 'Shipment delivered',
          message: 'This shipment is complete - live tracking has ended.',
        ),
      TrackingStatus.codeFailed => const _BannerContent(
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
          background: AppColors.dangerBg,
          title: 'Tracking failed',
          message:
              "We couldn't track this shipment. Please contact your fleet manager for next steps.",
        ),
      _ => const _BannerContent(
          icon: Icons.info_outline_rounded,
          color: AppColors.textMedium,
          background: Color(0xFFF1F5F9),
          title: 'Tracking status unavailable',
          message: "We couldn't determine the live tracking status for this shipment yet.",
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: content.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: content.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(content.icon, color: content.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: content.color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  content.message,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerContent {
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String message;

  const _BannerContent({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.message,
  });
}
