import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trip.dart';
import 'trip_status_chip.dart';

/// The dashboard's primary card: everything a driver needs about the shipment
/// they are currently running, without opening the details page.
class ActiveTripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onViewDetails;
  final VoidCallback onTrackMap;
  final VoidCallback onChangeBooking;
  final VoidCallback? onCallCustomer;

  const ActiveTripCard({
    super.key,
    required this.trip,
    required this.onViewDetails,
    required this.onTrackMap,
    required this.onChangeBooking,
    this.onCallCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final status = TripStatusStyle.of(trip.status);
    final metrics = _metrics();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status.isTerminal) _buildCompletedBanner(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildRoute(),
                if (metrics.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _buildMetrics(metrics),
                ],
                if (trip.customerName.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildCustomerRow(),
                ],
                const SizedBox(height: 18),
                _buildActions(status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.successBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This shipment is finished. Load a new Booking Order to start '
              'your next trip.',
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TripStatusChip(status: trip.status),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Booking ID: ',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMedium,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "#${trip.bookingId}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoute() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineTrack(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RouteStop(
                label: 'PICKUP',
                location: trip.pickupLocation,
                address: trip.pickupAddress,
                meta: trip.pickupDate,
              ),
              const SizedBox(height: 22),
              _RouteStop(
                label: 'DESTINATION',
                location: trip.dropLocation,
                address: trip.dropAddress,
                meta: trip.isShippingDone
                    ? (trip.formattedCompletedDate.isNotEmpty
                          ? trip.formattedCompletedDate
                          : trip.pickupDate)
                    : trip.dropEta,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTrack() {
    return Column(
      children: [
        const SizedBox(height: 14),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.navy, width: 2.5),
          ),
        ),
        const SizedBox(height: 4),
        Column(
          children: List.generate(
            6,
            (_) => Container(
              width: 2,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Icon(
          Icons.location_on_rounded,
          color: AppColors.accentGreen,
          size: 17,
        ),
      ],
    );
  }

  Widget _buildMetrics(List<_Metric> metrics) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < metrics.length; i++) ...[
              if (i > 0)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                  color: AppColors.border,
                ),
              Expanded(child: _MetricTile(metric: metrics[i])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerRow() {
    final hasPhone = trip.customerPhone.trim().isNotEmpty;
    final canCall = onCallCustomer != null && hasPhone;
    final cargo = [
      trip.cargoType.trim(),
      trip.weight.trim(),
    ].where((v) => v.isNotEmpty).join(' · ');

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.customerBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 19,
            color: AppColors.customerAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trip.customerName.isNotEmpty ? trip.customerName : 'Customer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              if (hasPhone) ...[
                const SizedBox(height: 2),
                Text(
                  trip.customerPhone.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
              ] else if (cargo.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  cargo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (canCall)
          Semantics(
            button: true,
            label: 'Call ${trip.customerName}',
            child: Material(
              color: const Color(0xFFDCFCE7),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCallCustomer!();
                },
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.phone_rounded,
                    size: 19,
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions(TripStatusStyle status) {
    final showTrackMap = trip.isTrackingStarted || status.isTrackingStarted;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.border),
                // / Reduce internal padding
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 17),
              label: const Text(
                'Details',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: onViewDetails,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: status.isTerminal
                    ? AppColors.accentGreen
                    : showTrackMap
                    ? AppColors.primary
                    : AppColors.primary,
                foregroundColor: Colors.white,
                // / Reduce internal padding
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),

              icon: Icon(
                status.isTerminal
                    ? Icons.add_circle_outline_rounded
                    : showTrackMap
                    ? Icons.route_rounded
                    : Icons.play_circle_outline_rounded,
                size: 17,
              ),
              label: Text(
                status.isTerminal
                    ? 'New Trip'
                    : showTrackMap
                    ? 'Track Status'
                    : 'Start Shipment',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: status.isTerminal ? onChangeBooking : onTrackMap,
            ),
          ),
        ),
      ],
    );
  }

  /// Only surfaces metrics the API actually returned, so the strip never shows
  /// a placeholder like `0 km`. Distance and ETA are dropped once the shipment
  /// is delivered — "128 km remaining" on a finished trip is just wrong.
  List<_Metric> _metrics() {
    final metrics = <_Metric>[];
    final isFinished = TripStatusStyle.of(trip.status).isTerminal;

    if (!isFinished && trip.distanceRemainingKm > 0) {
      metrics.add(
        _Metric(
          icon: Icons.straighten_rounded,
          value: _formatDistance(trip.distanceRemainingKm),
          label: 'Remaining',
        ),
      );
    }

    final eta = isFinished ? null : _formatEta(trip.etaHours);
    if (eta != null) {
      metrics.add(
        _Metric(icon: Icons.schedule_rounded, value: eta, label: 'ETA'),
      );
    }

    final transit = trip.transitTime?.trim() ?? '';
    if (transit.isNotEmpty) {
      metrics.add(
        _Metric(icon: Icons.schedule_rounded, value: transit, label: 'Transit'),
      );
    }

    final truck = trip.truckType.trim().isNotEmpty
        ? trip.truckType.trim()
        : trip.truckInfo.trim();
    if (truck.isNotEmpty) {
      metrics.add(
        _Metric(
          icon: Icons.local_shipping_outlined,
          value: truck,
          label: 'Vehicle',
        ),
      );
    }

    return metrics;
  }

  static String _formatDistance(double km) {
    if (km >= 100) return '${km.round()} km';
    return '${km.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')} km';
  }

  static String? _formatEta(double hours) {
    if (hours <= 0) return null;
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class _RouteStop extends StatelessWidget {
  final String label;
  final String location;
  final String address;
  final String meta;

  const _RouteStop({
    required this.label,
    required this.location,
    required this.address,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          location.trim().isNotEmpty ? location : 'Not provided',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.2,
          ),
        ),
        if (address.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            address.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ],
    );
  }
}

class _Metric {
  final IconData icon;
  final String value;
  final String label;

  const _Metric({required this.icon, required this.value, required this.label});
}

class _MetricTile extends StatelessWidget {
  final _Metric metric;

  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(metric.icon, size: 15, color: AppColors.textMedium),
          const SizedBox(height: 6),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
