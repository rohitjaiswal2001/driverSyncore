import 'package:geocoding/geocoding.dart';

/// Resolves a coordinate into the comma-separated
/// `area, district, state, country` string the tracking API takes as its
/// `address` field.
///
/// Uses the platform's own geocoder, so it costs no Google API quota. Every
/// lookup is best-effort: a failure, a timeout, or a coordinate the platform
/// cannot resolve all return null, and the caller sends the update without an
/// address. A driver's position reaching the backend is never worth failing
/// over a missing place name.
class ReverseGeocoder {
  /// Bounds the platform lookup. Deliberately short: this runs inside a
  /// tracking update, so a slow geocoder must not hold the coordinates back.
  static const Duration lookupTimeout = Duration(seconds: 8);

  final Geocoding _geocoding;

  ReverseGeocoder({Geocoding? geocoding})
    : _geocoding = geocoding ?? Geocoding();

  /// Returns `area, district, state, country` for the coordinate, or null if
  /// nothing usable could be resolved.
  Future<String?> addressFor(double latitude, double longitude) async {
    try {
      final placemarks = await _geocoding
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(lookupTimeout);

      // The platforms can hand back several placemarks, and the first is not
      // always the most complete - take the first that yields anything.
      for (final placemark in placemarks) {
        final address = formatPlacemark(placemark);
        if (address != null) return address;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Builds `area, district, state, country` from a single placemark.
  ///
  /// Each segment falls back through the fields the platforms actually
  /// populate - Android and iOS disagree about whether the neighbourhood lands
  /// in `subLocality` or `locality` - and any segment that comes back empty,
  /// or that merely repeats one already used, is dropped. A coordinate that
  /// only resolves to a country therefore yields `Norway`, never `, , , Norway`.
  static String? formatPlacemark(Placemark placemark) {
    final segments = <String?>[
      _firstUsable([
        placemark.subLocality,
        placemark.locality,
        placemark.thoroughfare,
        placemark.name,
      ]), // area
      _firstUsable([
        placemark.subAdministrativeArea,
        placemark.locality,
      ]), // district
      _firstUsable([placemark.administrativeArea]), // state
      _firstUsable([placemark.country]), // country
    ];

    final parts = <String>[];
    for (final segment in segments) {
      if (segment == null) continue;
      final isRepeat = parts.any(
        (part) => part.toLowerCase() == segment.toLowerCase(),
      );
      if (isRepeat) continue;
      parts.add(segment);
    }

    return parts.isEmpty ? null : parts.join(', ');
  }

  /// First value that carries real content. Guards against the literal string
  /// 'null', which the platform channels occasionally hand back.
  static String? _firstUsable(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'null') return trimmed;
    }
    return null;
  }
}
