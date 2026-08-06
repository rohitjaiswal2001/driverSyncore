import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/active_order_store.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';

class TripCompletedPage extends StatelessWidget {
  final String bookingId;

  /// Transit time from the booking (e.g. "2-3 Days"). Empty when unknown.
  final String transitTime;

  /// Drop location from the booking. Empty when unknown.
  final String dropLocation;

  const TripCompletedPage({
    super.key,
    required this.bookingId,
    this.transitTime = '',
    this.dropLocation = '',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Ensures parent route receives update signal
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top-left back button in body
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  onPressed: () => Navigator.pop(context, true),
                ),

                const Spacer(flex: 1),

                // Large Checked Circular Badge with shadow
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5), // Light green tint
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981), // Solid Emerald Green
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Trip Status Title
                const Center(
                  child: Text(
                    'Trip Finished',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Journey Finished Success Text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Your journey has been successfully finished. High five for a safe trip!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Details Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Booking ID Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'BOOKING ID',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMedium,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            bookingId,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      if (transitTime.isNotEmpty || dropLocation.isNotEmpty) ...[
                        const Divider(height: 24, color: AppColors.divider),
                        if (dropLocation.isNotEmpty)
                          _DetailRow(label: 'DESTINATION', value: dropLocation),
                        if (dropLocation.isNotEmpty && transitTime.isNotEmpty)
                          const SizedBox(height: 12),
                        if (transitTime.isNotEmpty)
                          _DetailRow(label: 'TRANSIT TIME', value: transitTime),
                      ],
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Primary Actions Row: View Tracking vs New Order ID
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text(
                      'View Tracking Status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showAppConfirmDialog(
                        context,
                        icon: Icons.swap_horiz_rounded,
                        title: 'Clear order ID?',
                        message:
                            'Your completed shipment will be cleared from the dashboard so you can enter a new Booking Order ID.',
                        confirmLabel: 'Clear Order',
                        accentColor: AppColors.navy,
                        accentBackground: AppColors.primaryLight,
                      );

                      if (confirmed && context.mounted) {
                        await di.sl<ActiveOrderStore>().clear();
                        if (context.mounted) {
                          // Pop back to the root route rather than replacing
                          // it. The root route owns the login/shell switch and
                          // renders the dashboard for the real signed-in user;
                          // rebuilding the shell here would discard that switch
                          // (stranding a later logout) and hardcode the name.
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    label: const Text(
                      'New Order ID',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textMedium,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
