import 'package:shared_preferences/shared_preferences.dart';

/// Persists the single "active" booking order ID the dashboard loaded.
///
/// Shared between the dashboard (which sets it) and the tracking page (which
/// reads it to know which trip to show live tracking for) so both pages agree
/// on what "the active trip" means without a dedicated backend concept for it.
class ActiveOrderStore {
  static const _key = 'active_booking_order_id';

  final SharedPreferences _prefs;

  const ActiveOrderStore(this._prefs);

  String? read() {
    final value = _prefs.getString(_key)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> set(String orderId) async {
    await _prefs.setString(_key, orderId.trim().toUpperCase());
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
