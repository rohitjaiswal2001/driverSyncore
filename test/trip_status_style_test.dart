import 'package:flutter_test/flutter_test.dart';
import 'package:syntracore_driver/features/trips/presentation/widgets/trip_status_chip.dart';

void main() {
  group('TripStatusStyle', () {
    test('marks started shipment statuses as tracking started', () {
      expect(TripStatusStyle.of('Trip Started').isTrackingStarted, isTrue);
      expect(TripStatusStyle.of('In Transit').isTrackingStarted, isTrue);
      expect(TripStatusStyle.of('ONGOING').isTrackingStarted, isTrue);
      expect(TripStatusStyle.of('SHIPMENT_START').isTrackingStarted, isTrue);
    });

    test('keeps pre-start statuses as not tracking started', () {
      expect(TripStatusStyle.of('Assigned').isTrackingStarted, isFalse);
      expect(TripStatusStyle.of('Reached Pickup').isTrackingStarted, isFalse);
      expect(TripStatusStyle.of('Loaded').isTrackingStarted, isFalse);
    });
  });
}
