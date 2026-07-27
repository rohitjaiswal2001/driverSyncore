import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trip.dart';
import '../bloc/trips_bloc.dart';
import '../bloc/trips_event.dart';
import '../bloc/trips_state.dart';
import 'trip_completed_page.dart';

class UpdateStatusPage extends StatefulWidget {
  final String tripId;
  final Trip? initialTrip;

  const UpdateStatusPage({super.key, required this.tripId, this.initialTrip});

  @override
  State<UpdateStatusPage> createState() => _UpdateStatusPageState();
}

class _UpdateStatusPageState extends State<UpdateStatusPage> {
  final List<String> _statusOptions = [
    'Reached Pickup',
    'Loaded',
    'Trip Started',
    'In Transit',
    'Reached Destination',
    'Delivered',
  ];

  final ValueNotifier<String?> _selectedStatus = ValueNotifier<String?>(null);
  Trip? _cachedTrip;

  @override
  void initState() {
    super.initState();
    _cachedTrip = widget.initialTrip;
    if (_cachedTrip != null) {
      _selectedStatus.value = _cachedTrip!.status;
    }
    // Load details to pre-select current status
    context.read<TripsBloc>().add(LoadTripDetails(tripId: widget.tripId));
  }

  @override
  void dispose() {
    _selectedStatus.dispose();
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
        title: const Text(
          'Update Trip Status',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textDark),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Help: Select the current state of your shipment.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<TripsBloc, TripsState>(
        listener: (context, state) {
          if (state is TripDetailsLoaded) {
            _cachedTrip = state.trip;
            // Set local selected status if not already set by user
            _selectedStatus.value ??= state.trip.status;
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
            final bookingId = trip.bookingId;
            final truckInfo = trip.truckInfo;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Booking details card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'BOOKING ID',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textLight,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    bookingId,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_shipping_outlined,
                                    size: 16,
                                    color: AppColors.textMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    truckInfo,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMedium,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'SELECT NEW STATUS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Status radio cards
                        ValueListenableBuilder<String?>(
                          valueListenable: _selectedStatus,
                          builder: (context, selectedValue, _) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _statusOptions.length,
                              itemBuilder: (context, index) {
                                final status = _statusOptions[index];
                                final isSelected = selectedValue == status;

                                return GestureDetector(
                                  onTap: () {
                                    _selectedStatus.value = status;
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: isSelected ? 1.8 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withAlpha(20),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      children: [
                                        // Custom Radio Button
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textLight,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Update Button Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: ValueListenableBuilder<String?>(
                    valueListenable: _selectedStatus,
                    builder: (context, selectedValue, _) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: selectedValue == null
                            ? null
                            : () {
                                context.read<TripsBloc>().add(
                                  UpdateTripStatus(
                                    tripId: widget.tripId,
                                    status: selectedValue,
                                  ),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Trip status updated to: $selectedValue',
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.accentGreen,
                                  ),
                                );

                                // Intelligently navigate to success page if delivered, otherwise pop once to details/progress
                                if (selectedValue == 'Delivered' ||
                                    selectedValue == 'Completed') {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TripCompletedPage(
                                        bookingId: bookingId,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.pop(context); // Pop update screen
                                }
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('Update'),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle_outline, size: 20),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
    );
  }
}
