import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Live Google Map for the "Trip In Progress" screen.
///
/// Shows the driver's current GPS position (when available) plus best-effort
/// pickup/destination pins resolved from the trip's free-text locations via
/// on-device geocoding (no extra Google API quota). Geocoding failures are
/// silent - the map still works with just the driver's live pin.
class LiveTrackingMap extends StatefulWidget {
  final LatLng? driverPosition;
  final String pickupLabel;
  final String dropLabel;
  final bool isLive;

  /// Short explanation shown as a small pill while the driver's own position
  /// is unavailable. The map itself stays fully visible and interactive - the
  /// route pins are useful even without GPS.
  final String? statusMessage;

  /// Status text displayed as an overlay pill at the top of the map area.
  final String? trackingStatusText;

  final BorderRadius borderRadius;

  const LiveTrackingMap({
    super.key,
    required this.driverPosition,
    required this.pickupLabel,
    required this.dropLabel,
    this.isLive = false,
    this.statusMessage,
    this.trackingStatusText,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  final Geocoding _geocoding = Geocoding();
  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  bool _hasCenteredOnDriver = false;

  @override
  void initState() {
    super.initState();
    _resolveEndpoints();
  }

  @override
  void didUpdateWidget(covariant LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickupLabel != widget.pickupLabel ||
        oldWidget.dropLabel != widget.dropLabel) {
      _resolveEndpoints();
    }
    if (widget.driverPosition != null &&
        widget.driverPosition != oldWidget.driverPosition) {
      _followDriver();
    }
  }

  Future<void> _resolveEndpoints() async {
    final pickup = await _geocode(widget.pickupLabel);
    final drop = await _geocode(widget.dropLabel);
    if (!mounted) return;
    setState(() {
      _pickupLatLng = pickup;
      _dropLatLng = drop;
    });
    _fitToVisibleMarkers();
  }

  Future<LatLng?> _geocode(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    try {
      final results = await _geocoding.locationFromAddress(trimmed);
      if (results.isEmpty) return null;
      return LatLng(results.first.latitude, results.first.longitude);
    } catch (_) {
      return null;
    }
  }

  void _followDriver() {
    final controller = _mapController;
    final position = widget.driverPosition;
    if (controller == null || position == null) return;

    if (!_hasCenteredOnDriver) {
      _hasCenteredOnDriver = true;
      controller.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
    } else {
      controller.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  void _fitToVisibleMarkers() {
    final controller = _mapController;
    if (controller == null) return;

    final points = <LatLng>[
      ?widget.driverPosition,
      ?_pickupLatLng,
      ?_dropLatLng,
    ];
    if (points.length < 2) return;

    final bounds = _boundsFor(points);
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
  }

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_pickupLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickupLabel),
        ),
      );
    }
    if (_dropLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: _dropLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: widget.dropLabel,
          ),
        ),
      );
    }
    if (widget.driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: widget.driverPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          zIndexInt: 2,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};
    final points = <LatLng>[];
    if (_pickupLatLng != null) points.add(_pickupLatLng!);
    if (widget.driverPosition != null) points.add(widget.driverPosition!);
    if (_dropLatLng != null) points.add(_dropLatLng!);

    if (points.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active_route'),
          points: points,
          color: AppColors.primary,
          width: 4,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget =
        widget.driverPosition ??
        _pickupLatLng ??
        const LatLng(20.5937, 78.9629);

    final waitingMessage = widget.driverPosition == null
        ? (widget.statusMessage ?? 'Locating driver…')
        : null;

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 12,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitToVisibleMarkers();
              if (widget.driverPosition != null) _followDriver();
            },
          ),

          // Top left: Status overlay pill
          if (widget.trackingStatusText != null &&
              widget.trackingStatusText!.isNotEmpty)
            Positioned(
              top: 14,
              left: 14,
              child: _StatusOverlayPill(
                label: widget.trackingStatusText!,
                isLive: widget.isLive,
              ),
            ),

          // Top right: Waiting/GPS status pill if driver location unavailable
          if (waitingMessage != null)
            Positioned(
              top: 14,
              right: 14,
              child: _MapStatusPill(
                icon: Icons.gps_not_fixed_rounded,
                label: waitingMessage,
              ),
            ),

          if (widget.isLive && widget.driverPosition != null)
            const Positioned(left: 16, top: 54, child: _LiveGpsBadge()),

          // Re-centre on the route (or the driver, once located).
          Positioned(
            right: 14,
            bottom: 14,
            child: _MapActionButton(
              icon: widget.driverPosition != null
                  ? Icons.my_location_rounded
                  : Icons.center_focus_strong_rounded,
              tooltip: widget.driverPosition != null
                  ? 'Centre on me'
                  : 'Fit route',
              onTap: () {
                if (widget.driverPosition != null) {
                  _hasCenteredOnDriver = false;
                  _followDriver();
                } else {
                  _fitToVisibleMarkers();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOverlayPill extends StatelessWidget {
  final String label;
  final bool isLive;

  const _StatusOverlayPill({required this.label, this.isLive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLive ? AppColors.accentGreen : AppColors.accentOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 21, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}

class _LiveGpsBadge extends StatelessWidget {
  const _LiveGpsBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          SizedBox(width: 6),
          Text(
            'GPS LIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.accentGreen,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MapStatusPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
