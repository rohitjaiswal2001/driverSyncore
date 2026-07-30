import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/tracking_status.dart';
import '../../domain/repositories/trips_repository.dart';
import '../bloc/trips_bloc.dart';
import '../bloc/trips_event.dart';
import '../bloc/trips_state.dart';
import '../controllers/location_tracking_controller.dart';
import '../widgets/direction_badge.dart';
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
  LocationTrackingController? _locationController;

  @override
  void initState() {
    super.initState();
    _cachedTrip = widget.initialTrip;
    context.read<TripsBloc>().add(LoadTripDetails(tripId: widget.tripId));
    _initTrackingController(widget.tripId);
  }

  void _initTrackingController(String orderId) {
    _locationController?.dispose();
    _locationController = LocationTrackingController(
      repository: di.sl<TripsRepository>(),
      orderId: orderId,
    );
    _locationController!.addListener(_onLocationChanged);
    _locationController!.updateTrackingStatus(
      const TrackingStatus(id: 2, code: 'ONGOING', label: 'Ongoing'),
    );
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _locationController?.removeListener(_onLocationChanged);
    _locationController?.dispose();
    super.dispose();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Live Tracking',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (_cachedTrip != null)
              Text(
                'Order #${_cachedTrip!.bookingId}',
                style: const TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () {
              context.read<TripsBloc>().add(LoadTripDetails(tripId: widget.tripId));
              _locationController?.retryLocationAccess();
            },
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
            final pos = _locationController?.currentPosition;
            final driverLatLng =
                pos != null ? LatLng(pos.latitude, pos.longitude) : null;
            final speedKmH = pos != null && pos.speed > 0
                ? '${(pos.speed * 3.6).toStringAsFixed(0)} km/h'
                : '62 km/h';

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Direction Badge Header Row
                  if (trip.direction != null && trip.direction!.isNotEmpty) ...[
                    Row(
                      children: [
                        DirectionBadge(direction: trip.direction),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            trip.status.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 1. Live Google Map Card at the Top
                  TripDetailsMapCard(
                    fromLocation: trip.pickupLocation,
                    toLocation: trip.dropLocation,
                    driverPosition: driverLatLng,
                    progress: 0.55,
                    isTripInProgress: true,
                    speedText: speedKmH,
                    height: 280,
                  ),
                  const SizedBox(height: 16),

                  // 2. Active Transit Status Bar
                  TransitStatusBar(
                    statusLabel: 'IN TRANSIT',
                    statusText: trip.status == 'Trip Started'
                        ? 'Moving to Destination'
                        : trip.status,
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
                  TripDocumentsCard(
                    documentUrl: trip.documentUrl,
                    bookingId: trip.bookingId,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
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
                onPressed: () async {
                  final bloc = context.read<TripsBloc>();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateStatusPage(
                        tripId: trip.id,
                        initialTrip: trip,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    bloc.add(LoadTripDetails(tripId: widget.tripId));
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.list_alt_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Update Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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
