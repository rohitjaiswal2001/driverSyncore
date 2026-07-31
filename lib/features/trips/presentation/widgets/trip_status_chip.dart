import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Colour, icon and semantics for a trip status string.
///
/// The backend sends free-text statuses, so lookup is case-insensitive and
/// falls back to a neutral style rather than rendering an unstyled chip.
class TripStatusStyle {
  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  const TripStatusStyle({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  /// True once the shipment is finished and the driver can take a new booking.
  bool get isTerminal {
    final normalised = label.toLowerCase();
    return normalised == 'completed' || normalised == 'delivered';
  }

  /// True once the shipment has already moved past the pre-start state and is
  /// actively being tracked.
  bool get isTrackingStarted {
    final normalised = label.toLowerCase();
    return normalised == 'trip started' ||
        normalised == 'in transit' ||
        normalised == 'ongoing' ||
        normalised == 'shipment_start';
  }

  static TripStatusStyle of(String status) {
    final label = status.trim().isEmpty ? 'Unknown' : status.trim();

    switch (label.toLowerCase()) {
      case 'assigned':
        return TripStatusStyle(
          label: label,
          color: AppColors.accentBlue,
          background: AppColors.infoBg,
          icon: Icons.assignment_ind_outlined,
        );
      case 'reached pickup':
        return TripStatusStyle(
          label: label,
          color: AppColors.warning,
          background: AppColors.warningBg,
          icon: Icons.place_outlined,
        );
      case 'loaded':
        return TripStatusStyle(
          label: label,
          color: AppColors.accentPurple,
          background: const Color(0xFFF3E8FF),
          icon: Icons.inventory_2_outlined,
        );
      case 'trip started':
      case 'in transit':
        return TripStatusStyle(
          label: label,
          color: AppColors.navy,
          background: AppColors.primaryLight,
          icon: Icons.local_shipping_outlined,
        );
      case 'reached destination':
        return TripStatusStyle(
          label: label,
          color: AppColors.accentOrange,
          background: const Color(0xFFFFF7ED),
          icon: Icons.flag_outlined,
        );
      case 'completed':
      case 'delivered':
        return TripStatusStyle(
          label: label,
          color: AppColors.success,
          background: AppColors.successBg,
          icon: Icons.check_circle_outline_rounded,
        );
      default:
        return TripStatusStyle(
          label: label,
          color: AppColors.textMedium,
          background: const Color(0xFFF1F5F9),
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class TripStatusChip extends StatelessWidget {
  final String status;
  final bool compact;

  const TripStatusChip({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final style = TripStatusStyle.of(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: compact ? 11 : 13, color: style.color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            style.label.toUpperCase(),
            style: TextStyle(
              color: style.color,
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
