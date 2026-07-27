import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/quote.dart';

/// A card widget representing a single Quote's overview, including its
/// ID, status, route timeline, estimated price, packaging details, and
/// quick actions like "Download" or "Accept".
class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onTap;
  final VoidCallback? onAccept;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.onTap,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = quote.status.toLowerCase() == 'pending' || 
                      quote.status.toUpperCase() == 'APPROVED' || 
                      quote.status.toUpperCase() == 'ON_REQUEST' ||
                      quote.status.toUpperCase() == 'CALCULATED';
    
    Color badgeColor;
    Color textColor;
    switch (quote.status.toUpperCase()) {
      case 'ON_REQUEST':
        badgeColor = const Color(0xFFE0F2FE);
        textColor = const Color(0xFF0284C7);
        break;
      case 'APPROVED':
        badgeColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        break;
      case 'CALCULATED':
        badgeColor = const Color(0xFFE0E7FF); // Light indigo
        textColor = const Color(0xFF4F46E5);  // Indigo
        break;
      case 'BOOKING_REQUESTED':
        badgeColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      case 'EXPIRED':
        badgeColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        break;
      case 'CANCELLED':
        badgeColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        break;
      default:
        badgeColor = const Color(0xFFFEF3C7);
        textColor = AppColors.accentOrange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Quote ID and Status Badge
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QUOTE ID',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          quote.quoteId,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quote.status.toUpperCase(),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              
              // Route and Price Info
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: AppColors.accentGreen),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  quote.pickupLocation,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 3.0),
                            child: SizedBox(
                              height: 12,
                              child: VerticalDivider(width: 1, color: AppColors.divider),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: AppColors.accentBlue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  quote.dropLocation,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'EST. AMOUNT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quote.price,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Details Grid (Vehicle, Weight, Date)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildSmallInfoChip(Icons.local_shipping_outlined, quote.vehicleType),
                    const SizedBox(width: 8),
                    _buildSmallInfoChip(Icons.scale_outlined, quote.weight),
                    const SizedBox(width: 8),
                    _buildSmallInfoChip(Icons.calendar_today_outlined, quote.date),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.divider),
              
              // Actions Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Download Link
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Downloading Quote ${quote.quoteId}...')),
                        );
                      },
                      icon: const Icon(Icons.download, size: 16, color: AppColors.textMedium),
                      label: const Text(
                        'Download Quote',
                        style: TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                      ),
                    ),
                    
                    // View Details Button / Accept Button
                    Row(
                      children: [
                        if (isPending && onAccept != null) ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: onAccept,
                            child: const Text(
                              'Accept Quote',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        TextButton(
                          onPressed: onTap,
                          child: const Row(
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  size: 16, color: AppColors.accentBlue),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMedium),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 10, color: AppColors.textMedium, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
