import 'dart:math' as math;
import 'dart:ui' as ui;

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

  /// Compass heading of the driver's last fix, in degrees. Turns the driver's
  /// puck into a pointed arrow facing the way they are travelling; null or a
  /// negative value (what the platforms report when standing still) falls back
  /// to a plain dot.
  final double? driverHeading;

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

  /// Space around the map's edges the host has already claimed - the status
  /// bar and its own close button in full screen, for instance. The map's
  /// overlays, controls and Google's own logo are all inset by it, so nothing
  /// lands under a notch or behind the host's chrome.
  final EdgeInsets overlayInsets;

  /// Called to open the map full screen. Supplying it is what puts the expand
  /// control on the map and arms the drag-down gesture; the full-screen page
  /// itself passes null so the map cannot expand out of an expanded map.
  final VoidCallback? onExpand;

  const LiveTrackingMap({
    super.key,
    required this.driverPosition,
    this.driverHeading,
    required this.pickupLabel,
    required this.dropLabel,
    this.isLive = false,
    this.statusMessage,
    this.trackingStatusText,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.overlayInsets = EdgeInsets.zero,
    this.onExpand,
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

  /// While true the camera keeps chasing the driver's pin. Off to begin with:
  /// the map opens on the whole journey - where the driver is, where they
  /// started and where they are going - rather than zoomed onto the pin with
  /// the route off-screen. The locate button turns it on.
  bool _isFollowingDriver = false;

  /// Set the moment the driver pans, pinches or zooms. Until then the map
  /// keeps re-fr₹aming itself as the pieces arrive (endpoints geocode, then the
  /// route, then the first GPS fix); afterwards their view is theirs to keep.
  bool _userAdjustedCamera = false;

  /// Our own `animateCamera` calls also fire [_onCameraMoveStarted], which
  /// would otherwise read as "the user grabbed the map". Camera moves that
  /// begin before this deadline are treated as ours.
  DateTime? _ignoreCameraMovesUntil;

  double _currentZoom = 12;
  MapType _mapType = MapType.normal;

  static const String _mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'AIzaSyCagA-geXsTnJ7YITQ92FwnCKGkMT9Zt6Y',
  );

  /// Route geometry is the one thing here that costs a Directions call, so it
  /// is shared across every map in the app: opening this map full screen, or
  /// rebuilding it, reuses the same route instead of paying for it again.
  static final Map<String, List<LatLng>> _routeCache = {};

  /// Same idea for the place lookups behind the start and destination pins.
  static final Map<String, LatLng> _geocodeCache = {};

  BitmapDescriptor? _directionArrowIcon;
  BitmapDescriptor? _driverArrowIcon;
  BitmapDescriptor? _driverDotIcon;
  bool _hasBuiltIcons = false;

  /// Pointer bookkeeping for the drag-down-to-expand gesture. The map claims
  /// gestures eagerly, so this watches raw pointer events instead of competing
  /// in the arena it would always lose.
  Offset? _dragStart;
  bool _didTriggerExpand = false;

  @override
  void initState() {
    super.initState();
    _resolveEndpoints();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasBuiltIcons) return;
    _hasBuiltIcons = true;
    _buildIcons(MediaQuery.of(context).devicePixelRatio);
  }

  Future<void> _buildIcons(double dpr) async {
    final arrow = await _renderIcon(28, dpr, _paintDirectionArrow);
    final driverArrow = await _renderIcon(38, dpr, _paintDriverArrow);
    final driverDot = await _renderIcon(26, dpr, _paintDriverDot);
    if (!mounted) return;
    setState(() {
      _directionArrowIcon = arrow;
      _driverArrowIcon = driverArrow;
      _driverDotIcon = driverDot;
    });
  }

  /// Paints one marker off-screen and hands it to the map as a PNG, drawn at
  /// the device's pixel ratio so it stays sharp on every display.
  Future<BitmapDescriptor> _renderIcon(
    double logicalSize,
    double dpr,
    void Function(Canvas canvas, double size) paint,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);
    paint(canvas, logicalSize);
    final pixels = (logicalSize * dpr).round();
    final image = await recorder.endRecording().toImage(pixels, pixels);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return BytesMapBitmap(data!.buffer.asUint8List(), imagePixelRatio: dpr);
  }

  /// A chevron pointing "north", which the map then rotates to the bearing of
  /// the leg it sits on. White casing underneath keeps it readable over both
  /// the road fill and satellite imagery.
  static void _paintDirectionArrow(Canvas canvas, double size) {
    final path = Path()
      ..moveTo(size / 2, size * 0.16)
      ..lineTo(size * 0.82, size * 0.8)
      ..lineTo(size / 2, size * 0.6)
      ..lineTo(size * 0.18, size * 0.8)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.16
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, Paint()..color = AppColors.primary);
  }

  /// The driver, travelling: a navigation arrow in a white collar, the shape
  /// every mapping app uses for "you, heading that way".
  static void _paintDriverArrow(Canvas canvas, double size) {
    final centre = Offset(size / 2, size / 2);
    canvas.drawCircle(
      centre,
      size * 0.42,
      Paint()..color = AppColors.primary.withValues(alpha: 0.18),
    );
    canvas.drawCircle(centre, size * 0.3, Paint()..color = Colors.white);

    final path = Path()
      ..moveTo(size / 2, size * 0.22)
      ..lineTo(size * 0.72, size * 0.74)
      ..lineTo(size / 2, size * 0.6)
      ..lineTo(size * 0.28, size * 0.74)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.primary);
  }

  /// The driver, stationary or without a heading: the familiar blue dot.
  static void _paintDriverDot(Canvas canvas, double size) {
    final centre = Offset(size / 2, size / 2);
    canvas.drawCircle(
      centre,
      size * 0.46,
      Paint()..color = AppColors.primary.withValues(alpha: 0.2),
    );
    canvas.drawCircle(centre, size * 0.3, Paint()..color = Colors.white);
    canvas.drawCircle(centre, size * 0.23, Paint()..color = AppColors.primary);
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
      // Following chases the pin; before the driver has touched the camera the
      // fresh fix is just one more thing the opening frame should include; and
      // once the view is theirs, the pin is still never allowed off screen.
      if (_isFollowingDriver) {
        _followDriver();
      } else if (!_userAdjustedCamera) {
        _autoFrame();
      } else {
        _keepDriverInFrame();
      }
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

    _autoFrame();
  }

  /// Frames everything worth seeing, until the driver takes the camera over.
  void _autoFrame() {
    if (_userAdjustedCamera || _isFollowingDriver) return;
    _fitToVisibleMarkers();
  }

  /// The driver's own pin is never allowed to drift off screen, however far
  /// they have panned. Only when it actually leaves the visible region does the
  /// camera move, and then it pans rather than zooms - their chosen zoom level
  /// survives, which a re-fit would throw away.
  Future<void> _keepDriverInFrame() async {
    final controller = _mapController;
    final driver = widget.driverPosition;
    if (controller == null || driver == null) return;

    try {
      final region = await controller.getVisibleRegion();
      // A map that has not laid out yet reports a zero-size region; nothing
      // useful to compare against, so leave the camera alone.
      if (region.southwest == region.northeast) return;
      if (region.contains(driver)) return;
    } catch (_) {
      return;
    }

    if (!mounted) return;
    await _animateCamera(CameraUpdate.newLatLng(driver));
  }

  /// Turns a trip's free-text place into a coordinate for its pin.
  ///
  /// The platform geocoder is tried first because it costs no quota, but it
  /// hands back nothing often enough - simulators, devices without Play
  /// Services, a throttled lookup - that relying on it alone left the map with
  /// no start pin, no destination pin and therefore no route at all. Google's
  /// own geocoder is the backstop, and the answer is cached for every map in
  /// the app.
  Future<LatLng?> _geocode(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    final cached = _geocodeCache[trimmed];
    if (cached != null) return cached;

    try {
      final results = await _geocoding.locationFromAddress(trimmed);
      if (results.isNotEmpty) {
        final resolved = LatLng(
          results.first.latitude,
          results.first.longitude,
        );
        return _geocodeCache[trimmed] = resolved;
      }
    } catch (_) {
      // Falls through to Google below.
    }

    final resolved = await _geocodeViaGoogle(trimmed);
    if (resolved != null) _geocodeCache[trimmed] = resolved;
    return resolved;
  }

  Future<LatLng?> _geocodeViaGoogle(String query) async {
    if (_mapsApiKey.isEmpty) return null;
    try {
      final response = await _apiClient.getExternal(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {'address': query, 'key': _mapsApiKey},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      final results = data['results'] as List? ?? const [];
      if (results.isEmpty) {
        debugPrint(
          '🗺️ [LiveTrackingMap] Could not place "$query": ${data['status']}',
        );
        return null;
      }

      final location =
          (results.first as Map?)?['geometry']?['location'] as Map?;
      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return LatLng(lat, lng);
    } catch (e) {
      debugPrint('🗺️ [LiveTrackingMap] Geocoding "$query" failed: $e');
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

    // A pan/pinch/double-tap from the driver: stop chasing the live pin, and
    // stop re-framing behind their back, until they ask for it back.
    _userAdjustedCamera = true;
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
    if (_mapsApiKey.isEmpty) return const [];

    final cacheKey =
        '${origin.latitude},${origin.longitude}'
        '|${destination.latitude},${destination.longitude}';
    final cached = _routeCache[cacheKey];
    if (cached != null) return cached;

    try {
      final response = await _apiClient.getExternal(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'key': _mapsApiKey,
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

      final decoded = decodeGooglePolyline(encodedPoints);
      if (decoded.isNotEmpty) _routeCache[cacheKey] = decoded;
      return decoded;
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
    if (points.isEmpty) return;

    // One known point - a driver whose pickup and drop both failed to geocode,
    // say - still deserves to be on screen rather than leaving the map parked
    // on its default camera.
    if (points.length == 1) {
      _currentZoom = 14;
      _animateCamera(CameraUpdate.newLatLngZoom(points.first, 14));
      return;
    }

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

    // Map convention, and the one every driver already knows from Google Maps:
    // green starts the journey, red ends it, blue is you.
    if (_pickupLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: 'Start', snippet: widget.pickupLabel),
        ),
      );
    }
    if (_dropLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: _dropLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: widget.dropLabel,
          ),
        ),
      );
    }

    markers.addAll(_buildDirectionMarkers());

    if (widget.driverPosition != null) {
      final heading = widget.driverHeading;
      // Android reports 0.0 when it has no heading to give, so a bare
      // ">= 0" would point every stationary driver due north.
      final hasHeading = heading != null && heading > 0;
      final icon = hasHeading ? _driverArrowIcon : _driverDotIcon;
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: widget.driverPosition!,
          icon:
              icon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          rotation: hasHeading ? heading : 0,
          zIndexInt: 3,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }
    return markers;
  }

  /// Chevrons spaced along the route, each turned to face the way the road is
  /// going, so the line reads as a direction of travel rather than a bare link
  /// between two pins. Deliberately few - a dense trail of arrows buries the
  /// road underneath at low zoom.
  Set<Marker> _buildDirectionMarkers() {
    final icon = _directionArrowIcon;
    final points = _routePoints;
    if (icon == null || points.length < 8) return const {};

    const arrowCount = 7;
    final markers = <Marker>{};
    final step = points.length / (arrowCount + 1);

    for (var i = 1; i <= arrowCount; i++) {
      final index = (step * i).floor();
      if (index <= 0 || index >= points.length - 1) continue;
      markers.add(
        Marker(
          markerId: MarkerId('route_arrow_$i'),
          position: points[index],
          icon: icon,
          rotation: _bearingBetween(points[index], points[index + 1]),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndexInt: 1,
          consumeTapEvents: true,
        ),
      );
    }
    return markers;
  }

  /// Initial bearing from one coordinate to the next, in degrees clockwise
  /// from north - the same convention [Marker.rotation] takes.
  static double _bearingBetween(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final deltaLng = (to.longitude - from.longitude) * math.pi / 180;

    final y = math.sin(deltaLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);

    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
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
      // Two lines, not one: a wider dark casing under the coloured route is
      // what keeps it legible over motorways and satellite imagery alike.
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active_route_casing'),
          points: points,
          color: AppColors.navy.withValues(alpha: 0.55),
          width: 11,
          zIndex: 0,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active_route'),
          points: points,
          color: AppColors.primary,
          width: 6,
          zIndex: 1,
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
    _userAdjustedCamera = false;

    final position = widget.driverPosition;
    if (position != null) {
      _currentZoom = _driverZoom;
      _animateCamera(CameraUpdate.newLatLngZoom(position, _driverZoom));
    } else {
      _fitToVisibleMarkers();
    }
  }

  void _handleExpand() {
    final onExpand = widget.onExpand;
    if (onExpand == null) return;
    HapticFeedback.mediumImpact();
    onExpand();
  }

  /// Drag-down-to-expand, watched at the pointer level. The map's own
  /// [EagerGestureRecognizer] wins every gesture arena it enters, so a
  /// competing drag recognizer would never fire; [Listener] sees the pointers
  /// regardless of who wins. Deliberately long and deliberately vertical, so
  /// panning the map a little never throws the driver into full screen.
  static const double _expandDragThreshold = 90;

  void _onPointerDown(PointerDownEvent event) {
    _dragStart = event.position;
    _didTriggerExpand = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (widget.onExpand == null || _didTriggerExpand) return;
    final start = _dragStart;
    if (start == null) return;

    final delta = event.position - start;
    if (delta.dy >= _expandDragThreshold && delta.dy > delta.dx.abs() * 2) {
      _didTriggerExpand = true;
      _handleExpand();
    }
  }

  void _endPointer(PointerEvent _) {
    _dragStart = null;
    _didTriggerExpand = false;
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

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _endPointer,
      onPointerCancel: _endPointer,
      child: ClipRRect(
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
              padding: EdgeInsets.only(
                top: 56 + widget.overlayInsets.top,
                right: 8 + widget.overlayInsets.right,
                bottom: 12 + widget.overlayInsets.bottom,
                left: 8 + widget.overlayInsets.left,
              ),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
                if (_isFollowingDriver && widget.driverPosition != null) {
                  _followDriver();
                } else {
                  // First frame the map can actually move: show the driver,
                  // the start and the destination together.
                  _autoFrame();
                }
              },
              onCameraMoveStarted: _onCameraMoveStarted,
              onCameraMove: _onCameraMove,
            ),

            // Top left: Status overlay pill
            if (widget.trackingStatusText != null &&
                widget.trackingStatusText!.isNotEmpty)
              Positioned(
                top: 14 + widget.overlayInsets.top,
                left: 14 + widget.overlayInsets.left,
                child: _StatusOverlayPill(
                  label: widget.trackingStatusText!,
                  isLive: widget.isLive,
                ),
              ),

            if (_remainingDistanceText().isNotEmpty)
              Positioned(
                top: 14 + widget.overlayInsets.top,
                right: 14 + widget.overlayInsets.right,
                child: _DistanceOverlayPill(
                  distanceText: _remainingDistanceText(),
                ),
              ),

            // Control column, bottom-aligned on the right. Which controls fit
            // depends on how tall the host made the map, so short cards drop the
            // optional ones instead of overflowing.
            Positioned(
              right: 12 + widget.overlayInsets.right,
              top: 56 + widget.overlayInsets.top,
              bottom: 12 + widget.overlayInsets.bottom,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Locate 44 + zoom pill 81 + layers 40, plus 10px gaps.
                  final availableHeight = constraints.maxHeight;
                  if (availableHeight < 60) return const SizedBox.shrink();
                  final hasRouteToFrame = _framablePoints().length >= 2;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.onExpand != null &&
                          availableHeight >= 250) ...[
                        _MapActionButton(
                          icon: Icons.open_in_full_rounded,
                          tooltip: 'Full screen (or drag the map down)',
                          size: 40,
                          onTap: _handleExpand,
                        ),
                        const SizedBox(height: 10),
                      ],
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
            "Status : " + label.toUpperCase(),
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
