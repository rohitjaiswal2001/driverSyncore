import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Runtime POST_NOTIFICATIONS permission for the live-tracking foreground
/// service notification.
///
/// From Android 13 this is a runtime permission, and it gates foreground
/// service notifications too: without it the tracking service still runs, but
/// its "tracking in progress" notification is kept out of the notification
/// shade (it only shows under the system Task Manager). geolocator does not ask
/// for it, so the app has to - handled natively in MainActivity.kt.
class NotificationPermission {
  static const MethodChannel _channel = MethodChannel(
    'globelink/notification_permission',
  );

  const NotificationPermission._();

  /// Returns true when the tracking notification is allowed to be shown.
  /// Non-Android platforms report true - they have no equivalent permission.
  static Future<bool> ensureGranted() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    try {
      final granted = await _channel.invokeMethod<bool>(
        'ensureNotificationPermission',
      );
      return granted ?? false;
    } on MissingPluginException {
      // Older host build without the channel: never block tracking over this.
      return false;
    } on PlatformException catch (e) {
      debugPrint('POST_NOTIFICATIONS request failed: ${e.message}');
      return false;
    }
  }
}
