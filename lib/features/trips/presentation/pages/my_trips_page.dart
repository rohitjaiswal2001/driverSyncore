import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../../core/utils/recent_orders_store.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../widgets/direction_badge.dart';
import '../widgets/route_timeline.dart';
import '../widgets/trip_status_chip.dart';
import 'trip_details_page.dart';

/// Lists the shipments this driver has looked up on this device.
///
/// There is no backend endpoint that returns "all orders assigned to me"
/// (see [RecentOrdersStore]), so each row here is a real
/// GET /shipment-details response for an order ID the driver previously
/// entered - never placeholder data. Looking up a new ID adds it to the list.
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
  final _searchController = TextEditingController();

  String _activeTab = 'Assigned';
  bool _isLoading = true;
  String? _loadError;
  List<Trip> _trips = const [];

  /// Order IDs remembered locally whose lookup failed this session (deleted
  /// server-side, not approved yet, offline...).
  final Map<String, String> _failedLookups = {};

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final orderIds = di.sl<RecentOrdersStore>().read();
    if (orderIds.isEmpty) {
      if (!mounted) return;
      setState(() {
        _trips = const [];
        _failedLookups.clear();
        _isLoading = false;
      });
      return;
    }

    final repository = di.sl<TripsRepository>();
    final results = await Future.wait(
      orderIds.map((id) async {
        try {
          return (
            id: id,
            trip: await repository.getTripDetails(id),
            error: null,
          );
        } catch (e) {
          return (
            id: id,
            trip: null,
            error: e.toString().replaceAll('Exception: ', ''),
          );
        }
      }),
    );

    if (!mounted) return;
    setState(() {
      _failedLookups
        ..clear()
        ..addEntries(
          results
              .where((r) => r.trip == null)
              .map((r) => MapEntry(r.id, r.error ?? 'Lookup failed')),
        );
      _trips = results.map((r) => r.trip).whereType<Trip>().toList();
      _isLoading = false;
      if (_trips.isEmpty && _failedLookups.isNotEmpty) {
        _loadError = _failedLookups.values.first;
      }
    });
  }

  /// Looks up a booking order ID typed into the search box and remembers it.
  Future<void> _lookUpOrder(String rawId) async {
    final orderId = rawId.trim().toUpperCase();
    if (orderId.isEmpty) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() => _isLoading = true);

    try {
      final trip = await di.sl<TripsRepository>().getTripDetails(orderId);
      await di.sl<RecentOrdersStore>().record(trip.bookingId);
      if (!mounted) return;
      _searchController.clear();
      await _loadTrips();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      TopSnackBar.show(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _forget(String orderId) async {
    await di.sl<RecentOrdersStore>().remove(orderId);
    await _loadTrips();
  }

  List<Trip> get _filteredTrips {
    final query = _searchController.text.toLowerCase().trim();
    return _trips.where((trip) {
      if (query.isNotEmpty) {
        final haystack = [
          trip.bookingId,
          trip.pickupLocation,
          trip.dropLocation,
          trip.cargoType,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      final isFinished = TripStatusStyle.of(trip.status).isTerminal;
      return _activeTab == 'Assigned' ? !isFinished : isFinished;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'My Trips',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textDark),
            onPressed: _isLoading ? null : _loadTrips,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndTabs(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchAndTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: _lookUpOrder,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: 'Search or add a Booking Order ID',
              hintStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textLight,
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Look up this order',
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      onPressed: () => _lookUpOrder(_searchController.text),
                    ),
              filled: true,
              fillColor: AppColors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.6,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTabButton('Assigned')),
                Expanded(child: _buildTabButton('Completed')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabName) {
    final isSelected = _activeTab == tabName;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabName),
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_trips.isEmpty && _loadError != null) {
      return _buildMessageState(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load your trips",
        message: _loadError!,
        actionLabel: 'Try again',
        onAction: _loadTrips,
      );
    }

    if (_trips.isEmpty) {
      return _buildMessageState(
        icon: Icons.local_shipping_outlined,
        title: 'No trips yet',
        message:
            'Look up a Booking Order ID above and it will be saved here for '
            'quick access.',
      );
    }

    final filtered = _filteredTrips;
    if (filtered.isEmpty) {
      return _buildMessageState(
        icon: _activeTab == 'Assigned'
            ? Icons.assignment_outlined
            : Icons.check_circle_outline,
        title: 'No $_activeTab trips',
        message: _searchController.text.trim().isEmpty
            ? 'Nothing here right now.'
            : 'No saved trip matches your search.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        children: [
          for (final trip in filtered) _buildTripCard(trip),
          if (_failedLookups.isNotEmpty) _buildFailedLookups(),
        ],
      ),
    );
  }

  Widget _buildFailedLookups() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_failedLookups.length} saved order'
                  '${_failedLookups.length == 1 ? '' : 's'} unavailable',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in _failedLookups.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.key} — ${entry.value}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: AppColors.warning,
                    ),
                    onPressed: () => _forget(entry.key),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: AppColors.textLight),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textLight,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
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
                      if (trip.direction != null) ...[
                        const SizedBox(height: 8),
                        DirectionBadge(direction: trip.direction, compact: true),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                TripStatusChip(status: trip.status, compact: true),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: RouteTimeline(
              pickupLocation: trip.pickupLocation,
              pickupAddress: trip.pickupAddress,
              pickupTime: trip.pickupDate,
              dropLocation: trip.dropLocation,
              dropAddress: trip.dropAddress,
              dropTime: trip.dropEta.isEmpty ? '' : 'Estimated: ${trip.dropEta}',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boxWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (trip.cargoType.isNotEmpty)
                      _buildInfoBox(
                        boxWidth,
                        Icons.inventory_2_outlined,
                        'Cargo',
                        trip.cargoType,
                      ),
                    if (trip.weight.isNotEmpty)
                      _buildInfoBox(
                        boxWidth,
                        Icons.line_weight,
                        'Weight',
                        trip.weight,
                      ),
                    if (trip.truckType.isNotEmpty)
                      _buildInfoBox(
                        boxWidth,
                        Icons.local_shipping_outlined,
                        'Container',
                        trip.truckType,
                      ),
                    if (trip.pickupDate.isNotEmpty)
                      _buildInfoBox(
                        boxWidth,
                        Icons.calendar_today_outlined,
                        'Pickup Date',
                        trip.pickupDate.split(',').first,
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TripDetailsPage(tripId: trip.id, initialTrip: trip),
                  ),
                );
                if (mounted) await _loadTrips();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
