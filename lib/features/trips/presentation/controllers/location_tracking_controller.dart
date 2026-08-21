import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/notification_permission.dart';
import '../../../../core/utils/reverse_geocoder.dart';
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
  final ReverseGeocoder reverseGeocoder;

  LocationTrackingController({
    required this.repository,
    required this.orderId,
    ReverseGeocoder? reverseGeocoder,
  }) : reverseGeocoder = reverseGeocoder ?? ReverseGeocoder();

  TrackingStatus? _trackingStatus;
  Position? _currentPosition;
  LocationAccessState _accessState = LocationAccessState.unknown;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _pingTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = ApiConstants.locationPingInterval.inSeconds;
  bool _disposed = false;
  bool _hasSentInitialPing = false;
  bool _isTrackingNotificationVisible = true;

  TrackingStatus? get trackingStatus => _trackingStatus;
  Position? get currentPosition => _currentPosition;
  LocationAccessState get accessState => _accessState;
  bool get isLiveTracking => _pingTimer != null;
  int get secondsRemaining => _secondsRemaining;

  /// False when Android denied POST_NOTIFICATIONS, i.e. tracking is running but
  /// the driver has no notification telling them so.
  bool get isTrackingNotificationVisible => _isTrackingNotificationVisible;

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

  /// The persistent "tracking in progress" notification Android shows for the
  /// location foreground service. Keeping the service in the foreground is what
  /// lets the position stream and the ping timer survive the app being
  /// backgrounded, so this notification is not decoration - it is the thing
  /// holding the process alive.
  ForegroundNotificationConfig get _trackingNotification =>
      ForegroundNotificationConfig(
        notificationTitle: 'GlobeLink Driver • Live tracking',
        notificationText: 'Sharing your location for shipment #$orderId',
        notificationChannelName: 'Live trip tracking',
        enableWakeLock: true,
        // Not dismissible: swiping it away would let the system reclaim the
        // service and silently stop tracking mid-trip.
        setOngoing: true,
      );

  /// Location settings for the live stream. Both platforms need their own
  /// background opt-in: a foreground-service notification on Android, and
  /// `allowBackgroundLocationUpdates` plus the blue status-bar indicator on iOS
  /// (which also needs UIBackgroundModes=location in Info.plist).
  LocationSettings _liveLocationSettings({int distanceFilter = 0}) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          intervalDuration: const Duration(seconds: 15),
          foregroundNotificationConfig: _trackingNotification,
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          activityType: ActivityType.automotiveNavigation,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
          pauseLocationUpdatesAutomatically: false,
        );
      default:
        return LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        );
    }
  }

  Future<void> _startLiveTracking() async {
    final granted = await _ensureLocationAccess();
    if (!granted) return;

    // Ask before the service starts, otherwise Android 13+ starts the service
    // with its notification suppressed and the driver gets no visible sign that
    // tracking is running.
    _isTrackingNotificationVisible =
        await NotificationPermission.ensureGranted();
    if (!_isTrackingNotificationVisible) {
      dev.log(
        '⚠️ [LocationTracking] POST_NOTIFICATIONS not granted - the tracking '
        'notification will not appear in the shade',
        name: 'LocationTracking',
      );
    }
    _safeNotify();

    try {
      _currentPosition ??= await Geolocator.getCurrentPosition(
        locationSettings: _liveLocationSettings(),
      );
      _safeNotify();
      if (_currentPosition != null && !_hasSentInitialPing) {
        _hasSentInitialPing = true;
        unawaited(_sendPing());
      }
    } catch (_) {}

    _positionSubscription ??=
        Geolocator.getPositionStream(
          locationSettings: _liveLocationSettings(distanceFilter: 10),
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

  /// Tears down the position stream and timers without disposing the
  /// controller, so a caller that does not own it - the logout listener, say -
  /// can stop the pings while the widget keeps its own `dispose()` duty.
  void stopTracking() => _stopLiveTracking();

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
      // Resolved right here, off the same fix that is about to be sent, so the
      // backend gets a readable place name next to the raw coordinates.
      final address = await reverseGeocoder.addressFor(
        position.latitude,
        position.longitude,
      );
      await repository.pingTrackingLocation(
        orderId: orderId,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
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
