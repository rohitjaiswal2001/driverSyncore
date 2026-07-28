import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syntracore_driver/core/widgets/user_avatar.dart';
import 'package:syntracore_driver/features/trips/domain/entities/trip.dart';
import 'package:syntracore_driver/features/trips/presentation/widgets/active_trip_card.dart';
import 'package:syntracore_driver/features/trips/presentation/widgets/booking_id_entry_card.dart';
import 'package:syntracore_driver/features/trips/presentation/widgets/dashboard_quick_action_grid.dart';
import 'package:syntracore_driver/features/trips/presentation/widgets/driver_profile_header.dart';
import 'package:syntracore_driver/features/trips/presentation/widgets/profile_setting_tile.dart';
import 'package:syntracore_driver/features/trips/presentation/widgets/trip_status_chip.dart';

Trip buildTrip({
  String status = 'In Transit',
  String customerName = 'Rahul Sharma',
  String customerPhone = '+919876543210',
  double distanceRemainingKm = 128.4,
  double etaHours = 3.35,
  String truckType = '14 Ft Truck',
}) {
  return Trip(
    id: '1',
    bookingId: 'BK-2026-10025',
    status: status,
    isNew: false,
    customerName: customerName,
    customerPhone: customerPhone,
    cargoType: 'Steel coils',
    weight: '12 T',
    truckInfo: 'MH01AB1234',
    truckType: truckType,
    pickupLocation: 'Mumbai',
    pickupAddress: 'Plot 42, MIDC Industrial Estate, Andheri East, Mumbai 400093',
    pickupDate: '28 Jul 2026, 08:30',
    dropLocation: 'Pune',
    dropAddress: 'Building C, Hinjewadi Phase 2, Pune 411057',
    dropEta: 'ETA 28 Jul, 14:00',
    distanceRemainingKm: distanceRemainingKm,
    etaHours: etaHours,
    currentLocation: 'Lonavala',
    arrivalRequirementText: 'Call on arrival',
    routePoints: const [],
  );
}

/// Renders [child] on a narrow phone so overflow shows up as a test failure.
Future<void> pumpNarrow(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(320 * 3, 700 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ActiveTripCard', () {
    testWidgets('lays out on a narrow screen without overflow', (tester) async {
      await pumpNarrow(
        tester,
        ActiveTripCard(
          trip: buildTrip(),
          onViewDetails: () {},
          onTrackMap: () {},
          onChangeBooking: () {},
          onCallCustomer: () {},
        ),
      );

      expect(find.text('Mumbai'), findsOneWidget);
      expect(find.text('Pune'), findsOneWidget);
      expect(find.text('BK-2026-10025'), findsOneWidget);
      expect(find.text('Track Map'), findsOneWidget);
    });

    testWidgets('handles long text and missing optional data', (tester) async {
      await pumpNarrow(
        tester,
        ActiveTripCard(
          trip: buildTrip(
            customerName: 'A Very Long Customer Company Name Private Limited',
            customerPhone: '',
            distanceRemainingKm: 0,
            etaHours: 0,
            truckType: '',
          ),
          onViewDetails: () {},
          onTrackMap: () {},
          onChangeBooking: () {},
        ),
      );

      // Truck falls back to truckInfo, so the metric strip still renders.
      expect(find.text('MH01AB1234'), findsOneWidget);
      // No phone number means no call affordance.
      expect(find.byIcon(Icons.phone_rounded), findsNothing);
    });

    testWidgets('swaps the primary action once the trip is delivered', (
      tester,
    ) async {
      await pumpNarrow(
        tester,
        ActiveTripCard(
          trip: buildTrip(status: 'Delivered'),
          onViewDetails: () {},
          onTrackMap: () {},
          onChangeBooking: () {},
        ),
      );

      expect(find.text('New Trip'), findsOneWidget);
      expect(find.text('Track Map'), findsNothing);
      // A finished shipment has no distance left to cover.
      expect(find.text('Remaining'), findsNothing);
      expect(find.text('ETA'), findsNothing);
      expect(find.text('14 Ft Truck'), findsOneWidget);
    });

    testWidgets('gives leftover header width to the booking id', (tester) async {
      await pumpNarrow(
        tester,
        ActiveTripCard(
          trip: buildTrip(),
          onViewDetails: () {},
          onTrackMap: () {},
          onChangeBooking: () {},
        ),
      );

      // A Spacer here would halve the space available to the booking chip and
      // ellipsize it even on wide screens.
      final header = tester.widget<Row>(
        find.ancestor(
          of: find.byType(TripStatusChip),
          matching: find.byType(Row),
        ).first,
      );
      expect(header.children.whereType<Spacer>(), isEmpty);
      expect(header.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    });
  });

  group('DriverProfileHeader', () {
    testWidgets('renders long identity values without overflow', (
      tester,
    ) async {
      await pumpNarrow(
        tester,
        const DriverProfileHeader(
          name: 'Ramesh Chandra Kumar Venkataraman',
          company: 'Syntracore Logistics And Fleet Services Private Limited',
          phone: '+91 98765 43210',
          email: 'ramesh.chandra.kumar@syntracore-logistics.example.com',
          isOnDuty: true,
          isVerified: false,
          onEditProfile: _noop,
        ),
      );

      expect(find.text('ON DUTY'), findsOneWidget);
      expect(find.text('UNVERIFIED'), findsOneWidget);
    });
  });

  group('DashboardQuickActionGrid', () {
    testWidgets('renders three actions side by side', (tester) async {
      var tapped = 0;
      await pumpNarrow(
        tester,
        DashboardQuickActionGrid(
          actions: [
            QuickAction(
              icon: Icons.article_rounded,
              label: 'Upload Docs',
              badge: 'SOON',
              onTap: () => tapped++,
            ),
            QuickAction(
              icon: Icons.headset_mic_rounded,
              label: 'Contact',
              onTap: () => tapped++,
            ),
            QuickAction(
              icon: Icons.route_rounded,
              label: 'My Trips',
              onTap: () => tapped++,
            ),
          ],
        ),
      );

      expect(find.text('SOON'), findsOneWidget);
      await tester.tap(find.text('Contact'));
      expect(tapped, 1);
    });
  });

  group('BookingIdEntryCard', () {
    testWidgets('uppercases input and gates the submit button', (tester) async {
      String? submitted;
      await pumpNarrow(
        tester,
        BookingIdEntryCard(onSubmit: (value) => submitted = value),
      );

      ElevatedButton submitButton() =>
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));

      // Nothing typed yet, so there is nothing to submit.
      expect(submitButton().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'bk-2026 10025');
      await tester.pump();

      // Lower case is normalised and whitespace is rejected.
      expect(find.text('BK-202610025'), findsOneWidget);
      expect(submitButton().onPressed, isNotNull);

      await tester.tap(find.text('Get Order Info'));
      await tester.pump();
      expect(submitted, 'BK-202610025');
    });

    testWidgets('shows a server error and clears it on the next edit', (
      tester,
    ) async {
      await pumpNarrow(
        tester,
        BookingIdEntryCard(
          onSubmit: (_) {},
          errorMessage: 'Booking order not found',
        ),
      );

      expect(find.text('Booking order not found'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'BK-1');
      await tester.pump();

      expect(find.text('Booking order not found'), findsNothing);
    });
  });

  group('ProfileSettingTile', () {
    testWidgets('renders a badge and reports taps', (tester) async {
      var tapped = false;
      await pumpNarrow(
        tester,
        ProfileSettingTile(
          icon: Icons.assignment_outlined,
          title: 'Documents',
          subtitle: 'KYC, permits and insurance',
          badge: 'SOON',
          onTap: () => tapped = true,
        ),
      );

      expect(find.text('SOON'), findsOneWidget);
      await tester.tap(find.text('Documents'));
      expect(tapped, isTrue);
    });
  });

  group('TripStatusStyle', () {
    test('maps known statuses case-insensitively', () {
      expect(TripStatusStyle.of('in transit').isTerminal, isFalse);
      expect(TripStatusStyle.of('DELIVERED').isTerminal, isTrue);
      expect(TripStatusStyle.of('Completed').isTerminal, isTrue);
    });

    test('falls back to a neutral style for unknown statuses', () {
      final style = TripStatusStyle.of('Something New');
      expect(style.label, 'Something New');
      expect(style.isTerminal, isFalse);
    });

    test('never renders an empty label', () {
      expect(TripStatusStyle.of('   ').label, 'Unknown');
    });
  });

  group('UserAvatar', () {
    test('derives up to two initials', () {
      expect(UserAvatar.initialsOf('Ramesh Kumar'), 'RK');
      expect(UserAvatar.initialsOf('Ramesh'), 'R');
      expect(UserAvatar.initialsOf('  ramesh   chandra  kumar '), 'RK');
      expect(UserAvatar.initialsOf(''), 'D');
    });
  });
}

void _noop() {}
