import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/tracking_status.dart';
import '../../domain/repositories/trips_repository.dart';

enum LocationAccessState {
  unknown,
  checking,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Drives the driver's live-location map marker and the backend location
/// ping loop for one trip.
///
/// Per product requirement, GPS streaming and the ~10s location ping only run
/// while the trip's tracking status is SHIPMENT_START or ONGOING
/// ([TrackingStatus.isLiveTrackingEligible]) - never before the driver starts,
/// and never once the shipment is done or has failed. Outside that window a
/// single best-effort position fetch still runs so the map has a starting pin.
class LocationTrackingController extends ChangeNotifier {
  static const _pingInterval = Duration(seconds: 10);

  final TripsRepository repository;
  final String orderId;

  LocationTrackingController({required this.repository, required this.orderId});

  TrackingStatus? _trackingStatus;
  Position? _currentPosition;
  LocationAccessState _accessState = LocationAccessState.unknown;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _pingTimer;
  bool _disposed = false;

  TrackingStatus? get trackingStatus => _trackingStatus;
  Position? get currentPosition => _currentPosition;
  LocationAccessState get accessState => _accessState;
  bool get isLiveTracking => _pingTimer != null;

  /// Call whenever the trip's tracking status changes (initial load, manual
  /// refresh, or after a status update) to start/stop the loop accordingly.
  Future<void> updateTrackingStatus(TrackingStatus? status) async {
    _trackingStatus = status;
    await _startLiveTracking();
    _safeNotify();
  }

  Future<void> _startLiveTracking() async {
    final granted = await _ensureLocationAccess();
    if (!granted) return;

    try {
      _currentPosition ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _safeNotify();
    } catch (_) {}

    _positionSubscription ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      _currentPosition = position;
      _safeNotify();
    });

    if (_pingTimer == null && (_trackingStatus?.isLiveTrackingEligible ?? false)) {
      _pingTimer = Timer.periodic(_pingInterval, (_) => _sendPing());
      unawaited(_sendPing()); // fire the first ping immediately
    }
  }

  void _stopLiveTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<void> _refreshOneShotPosition() async {
    if (_accessState != LocationAccessState.granted) {
      final granted = await _ensureLocationAccess();
      if (!granted) return;
    }
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
    } catch (_) {
      // Best-effort only - the map falls back to the pickup location.
    }
  }

  Future<void> _sendPing() async {
    final status = _trackingStatus;
    final position = _currentPosition;
    if (position == null) return;
    if (status != null && !status.isLiveTrackingEligible) return;

    await repository.pingTrackingLocation(
      orderId: orderId,
      latitude: position.latitude,
      longitude: position.longitude,
      status: status?.code ?? 'ONGOING',
      statusId: status?.id,
    );
  }

  /// Returns true once permission is granted and location services are on.
  Future<bool> _ensureLocationAccess() async {
    _accessState = LocationAccessState.checking;
    _safeNotify();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _accessState = LocationAccessState.serviceDisabled;
      _safeNotify();
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _accessState = LocationAccessState.denied;
      _safeNotify();
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      _accessState = LocationAccessState.deniedForever;
      _safeNotify();
      return false;
    }

    _accessState = LocationAccessState.granted;
    _safeNotify();
    return true;
  }

  /// Re-runs the permission/service check, e.g. after the driver returns from
  /// the system location settings screen.
  Future<void> retryLocationAccess() async {
    final status = _trackingStatus;
    if (status != null && status.isLiveTrackingEligible) {
      await _startLiveTracking();
    } else {
      await _refreshOneShotPosition();
    }
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopLiveTracking();
    super.dispose();
  }
}
