import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trip.dart';
import '../bloc/trips_bloc.dart';
import '../bloc/trips_event.dart';
import '../bloc/trips_state.dart';
import '../widgets/route_timeline.dart';
import '../widgets/trip_details_map_card.dart';
import '../widgets/customer_contact_card.dart';
import '../widgets/cargo_metrics_row.dart';
import '../widgets/trip_documents_card.dart';
import '../widgets/transit_status_bar.dart';
import '../widgets/truck_info_card.dart';
import 'update_status_page.dart';

class TripInProgressPage extends StatefulWidget {
  final String tripId;
  final Trip? initialTrip;

  const TripInProgressPage({super.key, required this.tripId, this.initialTrip});

  @override
  State<TripInProgressPage> createState() => _TripInProgressPageState();
}

class _TripInProgressPageState extends State<TripInProgressPage> {
  Trip? _cachedTrip;

  @override
  void initState() {
    super.initState();
    _cachedTrip = widget.initialTrip;
    // Load trip details
    context.read<TripsBloc>().add(LoadTripDetails(tripId: widget.tripId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Live Tracking',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<TripsBloc, TripsState>(
        listener: (context, state) {
          if (state is TripsError && _cachedTrip != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        builder: (context, state) {
          if (state is TripDetailsLoaded) {
            _cachedTrip = state.trip;
          }

          if (state is TripsLoading && _cachedTrip == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          } else if (state is TripsError && _cachedTrip == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(state.errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TripsBloc>().add(LoadTripDetails(tripId: widget.tripId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_cachedTrip != null) {
            final trip = _cachedTrip!;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live Map Card at the Top
                  TripDetailsMapCard(
                    fromLocation: trip.pickupLocation,
                    toLocation: trip.dropLocation,
                    progress: 0.55, // Mid-trip progress
                    isTripInProgress: true,
                    speedText: '62 km/h',
                  ),
                  const SizedBox(height: 16),

                  // 2. Active Transit Status Bar
                  TransitStatusBar(
                    statusLabel: 'IN TRANSIT',
                    statusText: trip.status == 'Trip Started' ? 'Moving to Destination' : trip.status,
                  ),
                  const SizedBox(height: 16),

                  // 3. Customer Info Card
                  CustomerContactCard(
                    customerName: trip.customerName,
                    customerPhone: trip.customerPhone,
                  ),
                  const SizedBox(height: 16),

                  // 4. Cargo details card
                  CargoMetricsRow(
                    cargoType: trip.cargoType,
                    weight: trip.weight,
                  ),
                  const SizedBox(height: 16),

                  // 5. Truck Info Card
                  TruckInfoCard(truckInfo: trip.truckInfo),
                  const SizedBox(height: 16),

                  // 6. Route details card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: RouteTimeline(
                      pickupLocation: trip.pickupLocation,
                      pickupAddress: trip.pickupAddress,
                      pickupTime: trip.pickupDate,
                      dropLocation: trip.dropLocation,
                      dropAddress: trip.dropAddress,
                      dropTime: 'Estimated: ${trip.dropEta}',
                      timeRequirement: trip.arrivalRequirementText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 7. Documents card
                  const TripDocumentsCard(),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        },
      ),
      bottomNavigationBar: BlocBuilder<TripsBloc, TripsState>(
        builder: (context, state) {
          if (state is TripDetailsLoaded) {
            _cachedTrip = state.trip;
          }
          if (_cachedTrip != null) {
            final trip = _cachedTrip!;
            return Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateStatusPage(
                        tripId: trip.id,
                        initialTrip: trip,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.list_alt_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Update Status'),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
