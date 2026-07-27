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
import '../widgets/truck_info_card.dart';
import 'trip_in_progress_page.dart';

class TripDetailsPage extends StatefulWidget {
  final String tripId;
  final Trip? initialTrip;

  const TripDetailsPage({super.key, required this.tripId, this.initialTrip});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
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
          'Trip Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textDark),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<TripsBloc, TripsState>(
        listener: (context, state) {
          if (state is TripDetailsLoaded) {
            _cachedTrip = state.trip;
            final trip = state.trip;
            if (trip.status == 'Trip Started' || trip.status == 'In Transit') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TripInProgressPage(tripId: trip.id, initialTrip: trip),
                ),
              );
            }
          }
          if (state is TripsError && _cachedTrip != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
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
                      context.read<TripsBloc>().add(
                        LoadTripDetails(tripId: widget.tripId),
                      );
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
                  // 1. Map Panel at the Top
                  TripDetailsMapCard(
                    fromLocation: trip.pickupLocation,
                    toLocation: trip.dropLocation,
                    progress: 0.08,
                    isTripInProgress: false,
                  ),
                  const SizedBox(height: 16),

                  // 2. Customer Section Card
                  CustomerContactCard(
                    customerName: trip.customerName,
                    customerPhone: trip.customerPhone,
                  ),
                  const SizedBox(height: 16),

                  // 3. Cargo Details Row
                  CargoMetricsRow(
                    cargoType: trip.cargoType,
                    weight: trip.weight,
                  ),
                  const SizedBox(height: 16),

                  // 4. Truck / Vehicle Card
                  TruckInfoCard(truckInfo: trip.truckInfo),
                  const SizedBox(height: 16),

                  // 5. Route Timeline Card
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

                  // 6. Documents List Card
                  const TripDocumentsCard(),
                  const SizedBox(height: 80), // bottom spacing
                ],
              ),
            );
          }
          return const Center(child: Text('Loading trip details...'));
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
                  context.read<TripsBloc>().add(
                    UpdateTripStatus(tripId: trip.id, status: 'Trip Started'),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.navigation, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Start Trip'),
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
