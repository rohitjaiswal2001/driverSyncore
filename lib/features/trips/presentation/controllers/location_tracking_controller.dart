import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/api_constants.dart';
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

/// Drives the driver's live-location map marker and background location service.
class LocationTrackingController extends ChangeNotifier {
  /// Single centralized location ping interval managed in ApiConstants.locationPingInterval
  static Duration get _pingInterval => ApiConstants.locationPingInterval;

  final TripsRepository repository;
  final String orderId;

  LocationTrackingController({required this.repository, required this.orderId});

  TrackingStatus? _trackingStatus;
  Position? _currentPosition;
  LocationAccessState _accessState = LocationAccessState.unknown;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _pingTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = ApiConstants.locationPingInterval.inSeconds;
  bool _disposed = false;
  bool _hasSentInitialPing = false;

  TrackingStatus? get trackingStatus => _trackingStatus;
  Position? get currentPosition => _currentPosition;
  LocationAccessState get accessState => _accessState;
  bool get isLiveTracking => _pingTimer != null;
  int get secondsRemaining => _secondsRemaining;

  /// Call whenever the trip's tracking status changes (initial load, manual
  /// refresh, or after a status update) to start/stop the loop accordingly.
  Future<void> updateTrackingStatus(TrackingStatus? status) async {
    _trackingStatus = status;
    if (status?.isLiveTrackingEligible ?? false) {
      await _startLiveTracking();
    } else {
      _stopLiveTracking();
    }
    _safeNotify();
  }

  Future<void> _startLiveTracking() async {
    final granted = await _ensureLocationAccess();
    if (!granted) return;

    try {
      _currentPosition ??= await Geolocator.getCurrentPosition(
        locationSettings: defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                intervalDuration: const Duration(seconds: 15),
                foregroundNotificationConfig: ForegroundNotificationConfig(
                  notificationTitle: "globelink Live Tracking",
                  notificationText:
                      "Tracking active shipment #$orderId in background...",
                  enableWakeLock: true,
                ),
              )
            : const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _safeNotify();
      if (_currentPosition != null && !_hasSentInitialPing) {
        _hasSentInitialPing = true;
        unawaited(_sendPing());
      }
    } catch (_) {}

    _positionSubscription ??=
        Geolocator.getPositionStream(
          locationSettings: defaultTargetPlatform == TargetPlatform.android
              ? AndroidSettings(
                  accuracy: LocationAccuracy.high,
                  distanceFilter: 10,
                  intervalDuration: const Duration(seconds: 15),
                  foregroundNotificationConfig: ForegroundNotificationConfig(
                    notificationTitle: "globelink Live Tracking",
                    notificationText:
                        "Tracking active shipment #$orderId in background...",
                    enableWakeLock: true,
                  ),
                )
              : const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  distanceFilter: 10,
                ),
        ).listen((position) {
          _currentPosition = position;
          _safeNotify();
          if (!_hasSentInitialPing &&
              (_trackingStatus?.isLiveTrackingEligible ?? false)) {
            _hasSentInitialPing = true;
            unawaited(_sendPing());
          }
        });

    if (_pingTimer == null &&
        (_trackingStatus?.isLiveTrackingEligible ?? false)) {
      _secondsRemaining = _pingInterval.inSeconds;
      _startCountdownTimer();

      _pingTimer = Timer.periodic(_pingInterval, (_) {
        _secondsRemaining = _pingInterval.inSeconds;
        _sendPing();
      });

      if (_currentPosition != null && !_hasSentInitialPing) {
        _hasSentInitialPing = true;
        unawaited(_sendPing());
      }
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
      } else {
        _secondsRemaining = _pingInterval.inSeconds;
      }
      _safeNotify();
    });
  }

  void _stopLiveTracking() {
    _hasSentInitialPing = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    const msg = '⏹️ [LocationTracking] Live tracking stopped';
    dev.log(msg, name: 'LocationTracking');
  }

  Future<void> _refreshOneShotPosition() async {
    if (_accessState != LocationAccessState.granted) {
      final granted = await _ensureLocationAccess();
      if (!granted) return;
    }
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      // Best-effort only
    }
  }

  Future<void> _sendPing() async {
    final status = _trackingStatus;
    final position = _currentPosition;
    if (position == null) {
      final msg =
          '⚠️ [LocationTracking] Skipping ping for #$orderId: GPS position is null';
      dev.log(msg, name: 'LocationTracking');
      return;
    }
    if (status != null && !status.isLiveTrackingEligible) return;

    final startMsg =
        '🚀 [LocationTracking] HITTING PING API for Order #$orderId (Interval: ${_pingInterval.inMinutes} mins) -> Lat: ${position.latitude}, Lng: ${position.longitude}, StatusId: ${status?.id ?? 3}';
    dev.log(startMsg, name: 'LocationTracking');
    debugPrint(startMsg);

    try {
      await repository.pingTrackingLocation(
        orderId: orderId,
        latitude: position.latitude,
        longitude: position.longitude,
        status: 'ONGOING',
        statusId: status?.id ?? 3,
      );
      final successMsg =
          '✅ [LocationTracking] Location Ping API SUCCESS for Order #$orderId';
      dev.log(successMsg, name: 'LocationTracking');
      debugPrint(successMsg);
      _safeNotify();
    } catch (e) {
      final errorMsg =
          '❌ [LocationTracking] Location Ping API ERROR for Order #$orderId: $e';
      dev.log(errorMsg, name: 'LocationTracking');
      debugPrint(errorMsg);
    }
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

  /// Re-runs the permission/service check
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
