import 'package:shared_preferences/shared_preferences.dart';

/// Persists the order IDs a driver has actually looked up on this device.
///
/// There is no backend endpoint that lists "all orders assigned to this
/// driver" (confirmed by probing the staging API - /trips, /my-trips,
/// /bookings and /driver/trips all 404). Until one exists, My Trips is built
/// from this locally-remembered list, each entry hydrated via the real
/// GET /shipment-details?order_id= call - so the list is never fabricated,
/// only incomplete (a driver only sees orders they, or the dashboard search,
/// have already looked up at least once).
class RecentOrdersStore {
  static const _key = 'recent_order_ids';
  static const _maxEntries = 30;

  final SharedPreferences _prefs;

  const RecentOrdersStore(this._prefs);

  /// Most-recently-looked-up order first.
  List<String> read() => _prefs.getStringList(_key) ?? const [];

  /// Moves [orderId] to the front, de-duplicated, capped at [_maxEntries].
  Future<void> record(String orderId) async {
    final trimmed = orderId.trim().toUpperCase();
    if (trimmed.isEmpty) return;

    final current = read().where((id) => id != trimmed).toList();
    current.insert(0, trimmed);
    if (current.length > _maxEntries) {
      current.removeRange(_maxEntries, current.length);
    }
    await _prefs.setStringList(_key, current);
  }

  Future<void> remove(String orderId) async {
    final trimmed = orderId.trim().toUpperCase();
    final current = read().where((id) => id != trimmed).toList();
    await _prefs.setStringList(_key, current);
  }
}
