import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/trips_bloc.dart';
import '../bloc/trips_event.dart';
import '../bloc/trips_state.dart';
import '../../domain/entities/trip.dart';
import '../widgets/route_timeline.dart';
import 'trip_details_page.dart';

class MyTripsPage extends StatefulWidget {
  final String userRole;
  final String username;
  final VoidCallback? onProfileTap;

  const MyTripsPage({
    super.key,
    required this.userRole,
    required this.username,
    this.onProfileTap,
  });

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  final ValueNotifier<String> _activeTab = ValueNotifier<String>('Assigned');
  final ValueNotifier<bool> _isSearching = ValueNotifier<bool>(false);
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load trips when page opens
    context.read<TripsBloc>().add(LoadTrips(role: widget.userRole));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _activeTab.dispose();
    _isSearching.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ValueListenableBuilder<bool>(
          valueListenable: _isSearching,
          builder: (context, isSearchingVal, _) {
            return AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: isSearchingVal
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textDark,
                      ),
                      onPressed: () {
                        _isSearching.value = false;
                        _searchController.clear();
                      },
                    )
                  : GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: const NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
                          ),
                          radius: 20,
                          child: const Align(
                            alignment: Alignment.bottomRight,
                            child: CircleAvatar(
                              backgroundColor: AppColors.driverAccent,
                              radius: 6,
                            ),
                          ),
                        ),
                      ),
                    ),
              title: isSearchingVal
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search bookings, routes, cargo...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : const Text(
                      'My Trips',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
              actions: isSearchingVal
                  ? [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textDark,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                    ]
                  : [
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.textDark,
                        ),
                        onPressed: () {
                          _isSearching.value = true;
                        },
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_outlined,
                              color: AppColors.textDark,
                            ),
                            onPressed: () => _showNotificationsSheet(context),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accentOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Tab Switcher
          ValueListenableBuilder<String>(
            valueListenable: _activeTab,
            builder: (context, activeTabVal, _) {
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton('Assigned', activeTabVal),
                      ),
                      Expanded(
                        child: _buildTabButton('Completed', activeTabVal),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Trips List Content
          Expanded(
            child: BlocBuilder<TripsBloc, TripsState>(
              builder: (context, state) {
                if (state is TripsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                } else if (state is TripsLoaded) {
                  return AnimatedBuilder(
                    animation: Listenable.merge([
                      _activeTab,
                      _searchController,
                    ]),
                    builder: (context, _) {
                      final activeTabVal = _activeTab.value;
                      final query = _searchController.text.toLowerCase().trim();

                      // Prepare list of trips, dynamically adding the logged-in Booking ID if not present
                      final displayTrips = List<Trip>.from(state.trips);
                      if (widget.userRole.toLowerCase() == 'driver' &&
                          widget.username.isNotEmpty) {
                        final hasLoggedTrip = displayTrips.any(
                          (trip) =>
                              trip.bookingId.toLowerCase() ==
                              widget.username.toLowerCase(),
                        );
                        if (!hasLoggedTrip) {
                          displayTrips.insert(
                            0,
                            Trip(
                              id: widget.username,
                              bookingId: widget.username,
                              status: 'Assigned',
                              isNew: true,
                              customerName: 'Rahul Sharma',
                              customerPhone: '+91 9876543210',
                              cargoType: 'Furniture',
                              weight: '500 KG',
                              truckInfo: 'MH01AB1234 - 14 Ft Truck',
                              truckType: '14 Ft Truck',
                              pickupLocation: 'To Koper Warehouse',
                              pickupAddress: 'To Koper, Maharashtra',
                              pickupDate: '24 Jun 2026, 10:00 AM',
                              dropLocation: 'Caspian Sea',
                              dropAddress: 'Okhla',
                              dropEta: '25 Jun 2026, 11:00 PM',
                              distanceRemainingKm: 850.0,
                              etaHours: 12.0,
                              currentLocation: 'Nashik, Maharashtra',
                              arrivalRequirementText:
                                  'Arrival required in 45 minutes',
                              routePoints: const [
                                'To Koper Warehouse, MH',
                                'Nashik, Maharashtra',
                                'Caspian Sea',
                              ],
                            ),
                          );
                        }
                      }

                      // Filter list based on selected tab and search query
                      final filteredTrips = displayTrips.where((trip) {
                        if (query.isNotEmpty) {
                          final matchBooking = trip.bookingId
                              .toLowerCase()
                              .contains(query);
                          final matchPickup = trip.pickupLocation
                              .toLowerCase()
                              .contains(query);
                          final matchDrop = trip.dropLocation
                              .toLowerCase()
                              .contains(query);
                          final matchCargo = trip.cargoType
                              .toLowerCase()
                              .contains(query);
                          if (!matchBooking &&
                              !matchPickup &&
                              !matchDrop &&
                              !matchCargo) {
                            return false;
                          }
                        }
                        if (activeTabVal == 'Assigned') {
                          return trip.status != 'Completed' &&
                              trip.status != 'Delivered';
                        } else {
                          return trip.status == 'Completed' ||
                              trip.status == 'Delivered';
                        }
                      }).toList();

                      if (filteredTrips.isEmpty) {
                        return _buildEmptyState(activeTabVal);
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTrips.length,
                        itemBuilder: (context, index) {
                          return _buildTripCard(context, filteredTrips[index]);
                        },
                      );
                    },
                  );
                } else if (state is TripsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage,
                          style: const TextStyle(color: AppColors.textMedium),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<TripsBloc>().add(
                              LoadTrips(role: widget.userRole),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: Text('Loading trips details...'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabName, String activeTabVal) {
    final isSelected = activeTabVal == tabName;
    return GestureDetector(
      onTap: () {
        _activeTab.value = tabName;
      },
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            tabName,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMedium,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String activeTabVal) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            activeTabVal == 'Assigned'
                ? Icons.assignment_outlined
                : Icons.check_circle_outline,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No $activeTabVal Trips Found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'There are currently no shipments here.',
            style: TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BOOKING ID',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMedium,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.bookingId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                if (trip.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          trip.status == 'In Transit' ||
                              trip.status == 'Trip Started'
                          ? AppColors.primaryLight
                          : AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trip.status,
                      style: TextStyle(
                        color:
                            trip.status == 'In Transit' ||
                                trip.status == 'Trip Started'
                            ? AppColors.primary
                            : AppColors.textMedium,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Timeline
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RouteTimeline(
              pickupLocation: trip.pickupLocation,
              pickupAddress: trip.pickupAddress,
              pickupTime: trip.pickupDate,
              dropLocation: trip.dropLocation,
              dropAddress: trip.dropAddress,
              dropTime: 'Estimated: ${trip.dropEta}',
            ),
          ),

          // Detail Info Grid (4 items: Cargo, Weight, Container, Pickup Date)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boxWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildInfoBox(
                      boxWidth,
                      Icons.inventory_2_outlined,
                      'Cargo',
                      trip.cargoType,
                    ),
                    _buildInfoBox(
                      boxWidth,
                      Icons.line_weight,
                      'Weight',
                      trip.weight,
                    ),
                    _buildInfoBox(
                      boxWidth,
                      Icons.local_shipping_outlined,
                      'Truck/Container',
                      trip.truckType,
                    ),
                    _buildInfoBox(
                      boxWidth,
                      Icons.calendar_today_outlined,
                      'Pickup Date',
                      trip.pickupDate.split(',')[0],
                    ),
                  ],
                );
              },
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final tripsBloc = context.read<TripsBloc>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TripDetailsPage(tripId: trip.id, initialTrip: trip),
                  ),
                ).then((_) {
                  tripsBloc.add(LoadTrips(role: widget.userRole));
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('View Details'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
    double width,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textMedium,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildNotificationTile(
                  icon: Icons.assignment_outlined,
                  color: AppColors.customerAccent,
                  title: 'New Trip Assigned',
                  subtitle:
                      'Trip BK-2026-10024 has been assigned to your vehicle.',
                  time: '2 mins ago',
                ),
                const SizedBox(height: 12),
                _buildNotificationTile(
                  icon: Icons.check_circle_outline,
                  color: AppColors.driverAccent,
                  title: 'Trip Started Successfully',
                  subtitle: 'You initiated the trip to Caspian Sea.',
                  time: '1 hour ago',
                ),
                const SizedBox(height: 12),
                _buildNotificationTile(
                  icon: Icons.info_outline,
                  color: AppColors.accentOrange,
                  title: 'Route Warning',
                  subtitle:
                      'Heavy traffic reported near Nashik bypass. Drive safely.',
                  time: '3 hours ago',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
