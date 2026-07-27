import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
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

class DriverTrackingPage extends StatefulWidget {
  const DriverTrackingPage({super.key});

  @override
  State<DriverTrackingPage> createState() => _DriverTrackingPageState();
}

class _DriverTrackingPageState extends State<DriverTrackingPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch LoadTrips for driver to ensure state is fresh
    context.read<TripsBloc>().add(const LoadTrips(role: 'driver'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text(
          'Live Tracking',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: () {
              context.read<TripsBloc>().add(const LoadTrips(role: 'driver'));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<TripsBloc, TripsState>(
        builder: (context, state) {
          if (state is TripsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          } else if (state is TripsError) {
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
                      context.read<TripsBloc>().add(const LoadTrips(role: 'driver'));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is TripsLoaded) {
            final activeTrips = state.trips.where((trip) =>
                trip.status == 'Trip Started' ||
                trip.status == 'In Transit' ||
                trip.status == 'Assigned' ||
                trip.status == 'Reached Pickup' ||
                trip.status == 'Loaded');

            if (activeTrips.isEmpty) {
              return _buildNoActiveTripsPlaceholder();
            }

            // Display the primary active trip
            final trip = activeTrips.first;
            final isStarted = trip.status == 'Trip Started' || trip.status == 'In Transit';

            return RefreshIndicator(
              onRefresh: () async {
                context.read<TripsBloc>().add(const LoadTrips(role: 'driver'));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Map Card
                    TripDetailsMapCard(
                      fromLocation: trip.pickupLocation,
                      toLocation: trip.dropLocation,
                      progress: isStarted ? 0.55 : 0.08,
                      isTripInProgress: isStarted,
                    ),
                    const SizedBox(height: 16),

                    // 2. Status Banner (if active)
                    if (isStarted) ...[
                      TransitStatusBar(
                        statusLabel: 'IN TRANSIT',
                        statusText: trip.status == 'Trip Started' ? 'Moving to Destination' : trip.status,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 3. Customer Card
                    CustomerContactCard(
                      customerName: trip.customerName,
                      customerPhone: trip.customerPhone,
                    ),
                    const SizedBox(height: 16),

                    // 4. Cargo / Weight Row
                    CargoMetricsRow(
                      cargoType: trip.cargoType,
                      weight: trip.weight,
                    ),
                    const SizedBox(height: 16),

                    // 5. Truck Info Card
                    TruckInfoCard(truckInfo: trip.truckInfo),
                    const SizedBox(height: 16),

                    // 6. Route Timeline
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

                    // 7. Documents
                    const TripDocumentsCard(),
                    const SizedBox(height: 20),

                    // 8. Action Button inside the body (or bottom nav area)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (isStarted) {
                            final tripsBloc = context.read<TripsBloc>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdateStatusPage(
                                  tripId: trip.id,
                                  initialTrip: trip,
                                ),
                              ),
                            ).then((_) {
                              tripsBloc.add(const LoadTrips(role: 'driver'));
                            });
                          } else {
                            context.read<TripsBloc>().add(
                              UpdateTripStatus(tripId: trip.id, status: 'Trip Started'),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isStarted ? Icons.list_alt_rounded : Icons.navigation,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isStarted ? 'Update Status' : 'Start Trip',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        },
      ),
    );
  }

  Widget _buildNoActiveTripsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.map_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Active Trips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'You currently do not have any active shipments or route tracking assignments.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
