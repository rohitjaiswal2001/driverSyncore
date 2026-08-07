import 'dart:math' as math;

import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart'
    show EagerGestureRecognizer, OneSequenceGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

List<LatLng> decodeGooglePolyline(String encoded) {
  final points = <LatLng>[];
  if (encoded.isEmpty) return points;

  var index = 0;
  final length = encoded.length;
  var lat = 0;
  var lng = 0;

  while (index < length) {
    var bit = 0;
    var result = 0;
    do {
      final byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << bit;
      bit += 5;
    } while (encoded.codeUnitAt(index - 1) - 63 >= 0x20);

    final deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += deltaLat;

    bit = 0;
    result = 0;
    do {
      final byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << bit;
      bit += 5;
    } while (encoded.codeUnitAt(index - 1) - 63 >= 0x20);

    final deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += deltaLng;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return points;
}

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
  static const double _minZoom = 3;
  static const double _maxZoom = 20;
  static const double _driverZoom = 15.5;
  static const double _zoomStep = 1;

  /// Lets the map claim pan/pinch gestures immediately instead of losing them
  /// to the scroll view both host screens embed it in. Without this the map is
  /// effectively frozen: every vertical drag is handed to the page scroll.
  static final Set<Factory<OneSequenceGestureRecognizer>> _mapGestures = {
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  final Geocoding _geocoding = Geocoding();
  final ApiClient _apiClient = di.sl<ApiClient>();
  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  List<LatLng> _routePoints = const [];
  bool _hasCenteredOnDriver = false;

  /// While true the camera keeps chasing the driver's pin. Any camera move the
  /// user makes themselves turns it off, so the map stops yanking itself back
  /// mid-inspection; the locate button turns it on again.
  bool _isFollowingDriver = true;

  /// Our own `animateCamera` calls also fire [_onCameraMoveStarted], which
  /// would otherwise read as "the user grabbed the map". Camera moves that
  /// begin before this deadline are treated as ours.
  DateTime? _ignoreCameraMovesUntil;

  double _currentZoom = 12;
  MapType _mapType = MapType.normal;

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
      _routePoints = const [];
    });

    if (pickup != null && drop != null) {
      final routePoints = await _fetchRoutePolyline(pickup, drop);
      if (!mounted) return;
      setState(() => _routePoints = routePoints);
    }

    if (_isFollowingDriver) {
      _fitToVisibleMarkers();
    }
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

  /// Every programmatic camera change goes through here so [_isFollowingDriver]
  /// only ever reacts to moves the user actually made.
  Future<void> _animateCamera(CameraUpdate update) async {
    final controller = _mapController;
    if (controller == null) return;

    _ignoreCameraMovesUntil = DateTime.now().add(
      const Duration(milliseconds: 500),
    );
    await controller.animateCamera(update);
  }

  void _followDriver() {
    final position = widget.driverPosition;
    if (position == null || !_isFollowingDriver) return;

    if (!_hasCenteredOnDriver) {
      _hasCenteredOnDriver = true;
      _currentZoom = 15;
      _animateCamera(CameraUpdate.newLatLngZoom(position, 15));
    } else {
      _animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  void _onCameraMoveStarted() {
    final deadline = _ignoreCameraMovesUntil;
    if (deadline != null && DateTime.now().isBefore(deadline)) return;

    // A pan/pinch/double-tap from the driver: stop chasing the live pin until
    // they ask for it back.
    if (_isFollowingDriver) {
      setState(() => _isFollowingDriver = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    final previousZoom = _currentZoom;
    _currentZoom = position.zoom;

    // Fires on every animation frame, so only rebuild when a zoom button
    // actually needs to change its enabled state.
    final crossedLimit =
        (previousZoom >= _maxZoom) != (_currentZoom >= _maxZoom) ||
        (previousZoom <= _minZoom) != (_currentZoom <= _minZoom);
    if (crossedLimit && mounted) setState(() {});
  }

  void _zoomBy(double delta) {
    if (_mapController == null) return;

    final target = (_currentZoom + delta).clamp(_minZoom, _maxZoom);
    if (target == _currentZoom) return;

    HapticFeedback.selectionClick();
    // Zooming with the buttons keeps follow mode on - it re-frames the driver
    // rather than walking away from them.
    _animateCamera(CameraUpdate.zoomTo(target));
    setState(() => _currentZoom = target);
  }

  void _toggleMapType() {
    HapticFeedback.selectionClick();
    setState(() {
      _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  Future<List<LatLng>> _fetchRoutePolyline(
    LatLng origin,
    LatLng destination,
  ) async {
    const apiKey = String.fromEnvironment(
      'MAPS_API_KEY',
      defaultValue: 'AIzaSyDKjnNPu8LL8i1S8ac3cXCEkJhJ6p5Por0',
    );

    if (apiKey.isEmpty) return const [];

    try {
      final response = await _apiClient.getExternal(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'key': apiKey,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return const [];

      final routes = data['routes'] as List? ?? const [];
      if (routes.isEmpty) return const [];

      final firstRoute = routes.first as Map<String, dynamic>?;
      final encodedPoints = firstRoute?['overview_polyline']?['points']
          ?.toString();
      if (encodedPoints == null || encodedPoints.isEmpty) return const [];

      return decodeGooglePolyline(encodedPoints);
    } catch (_) {
      return const [];
    }
  }

  /// Points worth keeping in frame: the driver, both endpoints and the route.
  List<LatLng> _framablePoints() {
    return <LatLng>[
      ?widget.driverPosition,
      ?_pickupLatLng,
      ?_dropLatLng,
      ..._routePoints,
    ];
  }

  void _fitToVisibleMarkers() {
    final points = _framablePoints();
    if (points.length < 2) return;

    _animateCamera(CameraUpdate.newLatLngBounds(_boundsFor(points), 56));
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

  String _remainingDistanceText() {
    final driver = widget.driverPosition;
    final destination = _dropLatLng;
    if (driver == null || destination == null) return '';

    final distanceKm = _calculateDistanceKm(driver, destination);
    if (distanceKm.isNaN || distanceKm.isInfinite) return '';

    final roundedDistance = distanceKm < 1
        ? distanceKm.toStringAsFixed(1)
        : distanceKm.toStringAsFixed(0);

    const averageSpeedKmh = 45.0;
    final etaMinutes = averageSpeedKmh <= 0
        ? 0
        : (distanceKm / averageSpeedKmh * 60).round();

    final etaText = etaMinutes < 60
        ? '$etaMinutes min'
        : '${(etaMinutes / 60).floor()}h ${etaMinutes % 60}m';

    return '$roundedDistance km • ETA $etaText';
  }

  double _calculateDistanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final lat1 = a.latitude * (3.141592653589793 / 180);
    final lat2 = b.latitude * (3.141592653589793 / 180);
    final deltaLng = (b.longitude - a.longitude) * (3.141592653589793 / 180);

    final haversine =
        (math.sin(lat1) * math.sin(lat2)) +
        (math.cos(lat1) * math.cos(lat2) * math.cos(deltaLng));
    final centralAngle = math.acos(haversine.clamp(-1.0, 1.0));
    return earthRadiusKm * centralAngle;
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};
    final points = _routePoints.isNotEmpty
        ? _routePoints
        : <LatLng>[?_pickupLatLng, ?_dropLatLng];

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

  /// Locate button: resumes following and snaps back to the driver. Falls back
  /// to framing the whole route while GPS has not produced a fix yet.
  void _centerOnDriverPosition() {
    if (_mapController == null) return;
    HapticFeedback.selectionClick();

    setState(() => _isFollowingDriver = true);
    _hasCenteredOnDriver = true;

    final position = widget.driverPosition;
    if (position != null) {
      _currentZoom = _driverZoom;
      _animateCamera(CameraUpdate.newLatLngZoom(position, _driverZoom));
    } else {
      _fitToVisibleMarkers();
    }
  }

  /// Zooms out to show pickup, destination and the driver in one frame.
  void _fitRoute() {
    if (_mapController == null) return;
    HapticFeedback.selectionClick();

    // Framing the route is a deliberate overview, not a follow: leaving follow
    // on would immediately zoom back to the driver on the next GPS tick.
    setState(() => _isFollowingDriver = false);
    _fitToVisibleMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget =
        widget.driverPosition ??
        _pickupLatLng ??
        const LatLng(20.5937, 78.9629);

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: _currentZoom,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            mapType: _mapType,
            // Every gesture the platform offers: pan, pinch, double-tap and
            // two-finger tap to zoom, two-finger rotate and tilt.
            gestureRecognizers: _mapGestures,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            minMaxZoomPreference: const MinMaxZoomPreference(
              _minZoom,
              _maxZoom,
            ),
            trafficEnabled: widget.isLive,
            // Keeps the native compass and Google logo clear of the pills and
            // the control column drawn over the map.
            padding: const EdgeInsets.only(
              top: 56,
              right: 8,
              bottom: 12,
              left: 8,
            ),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              if (!_isFollowingDriver) return;
              if (widget.driverPosition != null) {
                _followDriver();
              } else {
                _fitToVisibleMarkers();
              }
            },
            onCameraMoveStarted: _onCameraMoveStarted,
            onCameraMove: _onCameraMove,
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

          if (_remainingDistanceText().isNotEmpty)
            Positioned(
              top: 14,
              right: 14,
              child: _DistanceOverlayPill(
                distanceText: _remainingDistanceText(),
              ),
            ),

          // Control column, bottom-aligned on the right. Which controls fit
          // depends on how tall the host made the map, so short cards drop the
          // optional ones instead of overflowing.
          Positioned(
            right: 12,
            top: 56,
            bottom: 12,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Locate 44 + zoom pill 81 + layers 40, plus 10px gaps.
                final availableHeight = constraints.maxHeight;
                if (availableHeight < 60) return const SizedBox.shrink();
                final hasRouteToFrame = _framablePoints().length >= 2;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (availableHeight >= 210)
                      _MapActionButton(
                        icon: _mapType == MapType.normal
                            ? Icons.layers_rounded
                            : Icons.map_rounded,
                        tooltip: _mapType == MapType.normal
                            ? 'Satellite view'
                            : 'Map view',
                        size: 40,
                        onTap: _toggleMapType,
                      ),
                    if (availableHeight >= 150) ...[
                      const SizedBox(height: 10),
                      _MapZoomControls(
                        canZoomIn: _currentZoom < _maxZoom,
                        canZoomOut: _currentZoom > _minZoom,
                        onZoomIn: () => _zoomBy(_zoomStep),
                        onZoomOut: () => _zoomBy(-_zoomStep),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _MapActionButton(
                      icon: widget.driverPosition != null
                          ? Icons.my_location_rounded
                          : Icons.center_focus_strong_rounded,
                      tooltip: widget.driverPosition != null
                          ? (hasRouteToFrame
                                ? 'Centre on me (hold to fit route)'
                                : 'Centre on me')
                          : 'Fit route',
                      // Filled while the camera is locked to the driver, so the
                      // button doubles as an indicator of which mode you are in.
                      isActive:
                          _isFollowingDriver && widget.driverPosition != null,
                      onTap: _centerOnDriverPosition,
                      onLongPress: hasRouteToFrame ? _fitRoute : null,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Stacked zoom in / zoom out buttons in one rounded pill, Google Maps style.
class _MapZoomControls extends StatelessWidget {
  final bool canZoomIn;
  final bool canZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const _MapZoomControls({
    required this.canZoomIn,
    required this.canZoomOut,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomCell(
            icon: Icons.add_rounded,
            tooltip: 'Zoom in',
            enabled: canZoomIn,
            onTap: onZoomIn,
          ),
          Container(width: 26, height: 1, color: const Color(0x1A0F172A)),
          _ZoomCell(
            icon: Icons.remove_rounded,
            tooltip: 'Zoom out',
            enabled: canZoomOut,
            onTap: onZoomOut,
          ),
        ],
      ),
    );
  }
}

class _ZoomCell extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _ZoomCell({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 42,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? AppColors.navy
                : AppColors.navy.withValues(alpha: 0.28),
          ),
        ),
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

class _DistanceOverlayPill extends StatelessWidget {
  final String distanceText;

  const _DistanceOverlayPill({required this.distanceText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            distanceText.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
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
  final VoidCallback? onLongPress;
  final bool isActive;
  final double size;

  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.onLongPress,
    this.isActive = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? AppColors.primary : Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: size * 0.48,
              color: isActive ? Colors.white : AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}
