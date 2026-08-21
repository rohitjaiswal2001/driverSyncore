import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:globelink_driver/core/utils/reverse_geocoder.dart';

Placemark _pm({
  String? subLocality, String? locality, String? subAdministrativeArea,
  String? administrativeArea, String? country, String? thoroughfare,
  String? name,
}) => Placemark(
  subLocality: subLocality, locality: locality,
  subAdministrativeArea: subAdministrativeArea,
  administrativeArea: administrativeArea, country: country,
  thoroughfare: thoroughfare, name: name,
);

void main() {
  test('full placemark -> area, district, state, country', () {
    expect(
      ReverseGeocoder.formatPlacemark(_pm(
        subLocality: 'Andheri East', subAdministrativeArea: 'Mumbai Suburban',
        administrativeArea: 'Maharashtra', country: 'India')),
      'Andheri East, Mumbai Suburban, Maharashtra, India',
    );
  });

  test('falls back to locality when subLocality is empty (iOS shape)', () {
    expect(
      ReverseGeocoder.formatPlacemark(_pm(
        subLocality: '', locality: 'Koper', administrativeArea: 'Obalno',
        country: 'Slovenia')),
      'Koper, Obalno, Slovenia',
    );
  });

  test('does not repeat a value used by two segments', () {
    // locality feeds both area and district when subLocality/subAdmin are blank
    expect(
      ReverseGeocoder.formatPlacemark(_pm(
        locality: 'Oslo', administrativeArea: 'Oslo', country: 'Norway')),
      'Oslo, Norway',
    );
  });

  test('country-only coordinate yields no empty commas', () {
    expect(ReverseGeocoder.formatPlacemark(_pm(country: 'Norway')), 'Norway');
  });

  test('literal "null" strings are ignored', () {
    expect(
      ReverseGeocoder.formatPlacemark(_pm(
        subLocality: 'null', locality: '  ', administrativeArea: 'Bavaria',
        country: 'Germany')),
      'Bavaria, Germany',
    );
  });

  test('entirely empty placemark -> null', () {
    expect(ReverseGeocoder.formatPlacemark(_pm()), isNull);
  });

  test('thoroughfare/name backstop the area segment', () {
    expect(
      ReverseGeocoder.formatPlacemark(_pm(
        thoroughfare: 'Storgata', administrativeArea: 'Oslo',
        country: 'Norway')),
      'Storgata, Oslo, Norway',
    );
  });
}
