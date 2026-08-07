import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/active_order_store.dart';
import '../../../../core/utils/bloc_refresh.dart';
import '../../domain/entities/trip.dart';
import '../bloc/trips_bloc.dart';
import '../bloc/trips_event.dart';
import '../bloc/trips_state.dart';
import '../widgets/cargo_metrics_row.dart';
import '../widgets/customer_contact_card.dart';
import '../widgets/route_timeline.dart';
import '../widgets/trip_documents_card.dart';
import '../widgets/truck_info_card.dart';
import 'driver_tracking_page.dart';

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
    // Always hit shipment details API on page entry
    context.read<TripsBloc>().add(LoadTripDetails(tripId: widget.tripId));
  }

  Future<void> _handleRefresh() async {
    return handleRefresh(
      context,
      () => context.read<TripsBloc>().refreshWith(
        LoadTripDetails(tripId: widget.tripId),
        isTerminal: (state) =>
            state is TripDetailsLoaded || state is TripsError,
      ),
    );
  }

  bool _checkIsCompleted(Trip trip) {
    return trip.isShippingDone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trip Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_cachedTrip != null && _cachedTrip!.bookingId.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _cachedTrip!.bookingId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: BlocConsumer<TripsBloc, TripsState>(
        listener: (context, state) {
          if (state is TripDetailsLoaded) {
            _cachedTrip = state.trip;
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
            final isCompleted = _checkIsCompleted(trip);
            final statusText = trip.trackingStatusLabel ?? trip.status;

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Route Timeline Card
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
                        dropTime: isCompleted
                            ? (trip.formattedCompletedDate.isNotEmpty
                                  ? 'Completed: ${trip.formattedCompletedDate}'
                                  : 'Completed: ${trip.pickupDate}')
                            : 'Estimated: ${trip.dropEta}',
                        timeRequirement: trip.arrivalRequirementText,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Customer Section Card
                    CustomerContactCard(
                      customerName: trip.customerName,
                      customerPhone: trip.customerPhone,
                    ),
                    const SizedBox(height: 16),

                    // 3. Current Shipment Status Banner Card (Placed below Customer details)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.accentGreen.withValues(alpha: 0.10)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.accentGreen.withValues(alpha: 0.35)
                              : AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.accentGreen.withValues(alpha: 0.2)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.local_shipping_rounded,
                              color: isCompleted
                                  ? AppColors.accentGreen
                                  : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CURRENT SHIPMENT STATUS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMedium,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? AppColors.accentGreen
                                        : AppColors.primary,
                                  ),
                                ),
                                if (isCompleted &&
                                    (trip.formattedCompletedDate.isNotEmpty ||
                                        trip.pickupDate.isNotEmpty)) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Date: ${trip.formattedCompletedDate.isNotEmpty ? trip.formattedCompletedDate : trip.pickupDate}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentGreen,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'COMPLETED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Cargo Details Row (Cargo, Weight, Distance)
                    CargoMetricsRow(
                      cargoType: trip.cargoType,
                      weight: trip.weight,
                      distanceKm: trip.distanceRemainingKm,
                    ),
                    const SizedBox(height: 16),

                    // 5. Truck / Vehicle Card
                    TruckInfoCard(truckInfo: trip.truckInfo),
                    const SizedBox(height: 16),

                    // // 6. Shipment Documents Card (Positioned at the bottom)
                    // TripDocumentsCard(
                    //   documentUrl: trip.documentUrl,
                    //   bookingId: trip.bookingId,
                    // ),
                    // const SizedBox(height: 32),
                  ],
                ),
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
            final isCompleted = _checkIsCompleted(trip);

            if (isCompleted) {
              return Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accentGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.accentGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        (trip.formattedCompletedDate.isNotEmpty ||
                                trip.pickupDate.isNotEmpty)
                            ? 'Shipping Completed on ${trip.formattedCompletedDate.isNotEmpty ? trip.formattedCompletedDate : trip.pickupDate}'
                            : 'Shipping is Completed',
                        style: const TextStyle(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isStarted = trip.isTrackingStarted;
            final buttonText = isStarted ? 'Track Shipment' : 'Start Trip';

            return Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await di.sl<ActiveOrderStore>().set(trip.bookingId);
                  if (!context.mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriverTrackingPage(),
                    ),
                  );
                  if (!context.mounted) return;
                  context.read<TripsBloc>().add(
                    LoadTripDetails(tripId: widget.tripId),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.navigation, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
