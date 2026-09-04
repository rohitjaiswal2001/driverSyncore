import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../../../core/theme/app_colors.dart';
import '../controllers/location_tracking_controller.dart';
import '../widgets/live_tracking_map.dart';

/// The tracking map with nothing else on screen.
///
/// Reached by dragging the map down (or the expand control), and fed the same
/// [LocationTrackingController] as the screen behind it, so the driver's pin
/// keeps moving while it is open rather than freezing on the position it was
/// opened with.
class FullScreenMapPage extends StatefulWidget {
  final LocationTrackingController? controller;
  final String pickupLabel;
  final String dropLabel;
  final String? trackingStatusText;
  final String Function(LocationAccessState state)? statusMessageBuilder;

  const FullScreenMapPage({
    super.key,
    this.controller,
    required this.pickupLabel,
    required this.dropLabel,
    this.trackingStatusText,
    this.statusMessageBuilder,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  /// Width the close button takes out of the top-left corner, so the map's own
  /// status pill starts beside it rather than underneath it.
  static const double _closeButtonColumn = 56;

  final GlobalKey _legendKey = GlobalKey();
  double _legendHeight = 0;

  @override
  void initState() {
    super.initState();
    // The legend's height depends on how far the place names wrap, so it is
    // measured rather than guessed: the map's controls and Google's own logo
    // are then held clear of whatever it actually turned out to be.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureLegend());
  }

  void _measureLegend() {
    if (!mounted) return;
    final box = _legendKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    if ((box.size.height - _legendHeight).abs() < 0.5) return;
    setState(() => _legendHeight = box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final legendOffset = mediaQuery.padding.bottom + 16;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMap(
              EdgeInsets.only(
                top: mediaQuery.padding.top,
                left: _closeButtonColumn,
                bottom: legendOffset + _legendHeight + 12,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: mediaQuery.padding.top + 12,
            child: _CloseButton(onTap: () => Navigator.pop(context)),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: legendOffset,
            child: _RouteLegend(
              key: _legendKey,
              pickup: widget.pickupLabel,
              drop: widget.dropLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(EdgeInsets overlayInsets) {
    final trackingController = widget.controller;
    if (trackingController == null) {
      return _map(position: null, isLive: false, overlayInsets: overlayInsets);
    }
    return AnimatedBuilder(
      animation: trackingController,
      builder: (context, _) {
        final position = trackingController.currentPosition;
        return _map(
          position: position == null
              ? null
              : LatLng(position.latitude, position.longitude),
          heading: position?.heading,
          isLive: trackingController.isLiveTracking,
          accessState: trackingController.accessState,
          overlayInsets: overlayInsets,
        );
      },
    );
  }

  Widget _map({
    required LatLng? position,
    required bool isLive,
    required EdgeInsets overlayInsets,
    double? heading,
    LocationAccessState accessState = LocationAccessState.unknown,
  }) {
    return LiveTrackingMap(
      driverPosition: position,
      driverHeading: heading,
      pickupLabel: widget.pickupLabel,
      dropLabel: widget.dropLabel,
      isLive: isLive,
      trackingStatusText: widget.trackingStatusText,
      statusMessage: widget.statusMessageBuilder?.call(accessState),
      borderRadius: BorderRadius.zero,
      overlayInsets: overlayInsets,
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.close_rounded, size: 22, color: AppColors.textDark),
        ),
      ),
    );
  }
}

/// Names the two ends of the route in the same colours their pins carry.
class _RouteLegend extends StatelessWidget {
  final String pickup;
  final String drop;

  const _RouteLegend({super.key, required this.pickup, required this.drop});

  @override
  Widget build(BuildContext context) {
    if (pickup.trim().isEmpty && drop.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendRow(
            color: AppColors.accentGreen,
            label: 'START',
            value: pickup,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 5, top: 4, bottom: 4),
            child: SizedBox(
              height: 12,
              child: VerticalDivider(
                width: 2,
                thickness: 2,
                color: AppColors.border,
              ),
            ),
          ),
          _LegendRow(
            color: AppColors.danger,
            label: 'DESTINATION',
            value: drop,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value.isEmpty ? '—' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
