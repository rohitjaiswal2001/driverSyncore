import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/active_order_store.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/tracking_status.dart';
import '../../domain/repositories/trips_repository.dart';
import '../controllers/location_tracking_controller.dart';
import '../widgets/booking_id_entry_card.dart';
import '../widgets/cargo_metrics_row.dart';
import '../widgets/customer_contact_card.dart';
import '../widgets/live_tracking_map.dart';
import 'update_status_page.dart';

class DriverTrackingPage extends StatefulWidget {
  const DriverTrackingPage({super.key});

  @override
  State<DriverTrackingPage> createState() => _DriverTrackingPageState();
}

class _DriverTrackingPageState extends State<DriverTrackingPage> {
  Trip? _activeTrip;
  List<TrackingStatus> _trackingStatuses = const [];
  LocationTrackingController? _locationController;

  bool _isLoading = true;
  bool _isTrackingEnabled = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTrackingStatuses();
    _loadActiveTrip();
  }

  /// The dashboard persists which booking order is "active"; live tracking
  /// follows that same order so both screens agree on the current shipment.
  /// Hits `GET /shipment-details?order_id=...` via [TripsRepository.getTripDetails].
  Future<void> _loadActiveTrip() async {
    final orderId = di.sl<ActiveOrderStore>().read();
    if (orderId == null) {
      if (!mounted) return;
      setState(() {
        _activeTrip = null;
        _isLoading = false;
        _loadError = null;
      });
      _locationController?.dispose();
      _locationController = null;
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final trip = await di.sl<TripsRepository>().getTripDetails(orderId);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
      _handleActiveTrip(trip);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _fetchTripForBookingId(String bookingId) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final trip = await di.sl<TripsRepository>().getTripDetails(bookingId);
      await di.sl<ActiveOrderStore>().set(bookingId);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
      _handleActiveTrip(trip);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _locationController?.dispose();
    super.dispose();
  }

  Future<void> _loadTrackingStatuses() async {
    try {
      final statuses = await di.sl<TripsRepository>().getTrackingStatuses();
      if (mounted) setState(() => _trackingStatuses = statuses);
      _applyTrackingStatusToController();
    } catch (_) {
      // Best effort load for status resolutions.
    }
  }

  /// Resolves the active trip's tracking-status code against the fetched
  /// `/tracking-statuses` list.
  TrackingStatus? _resolveTrackingStatus(Trip trip) {
    final code = trip.trackingStatusCode;
    if (code == null || code.isEmpty) return null;

    for (final status in _trackingStatuses) {
      if (status.code == code) return status;
    }
    if (trip.trackingStatusId != null) {
      return TrackingStatus(
        id: trip.trackingStatusId!,
        code: code,
        label: trip.trackingStatusLabel ?? code,
      );
    }
    return null;
  }

  void _handleActiveTrip(Trip trip) {
    final isNewTrip = _activeTrip?.bookingId != trip.bookingId;
    _activeTrip = trip;

    if (isNewTrip) {
      _locationController?.dispose();
      _locationController = LocationTrackingController(
        repository: di.sl<TripsRepository>(),
        orderId: trip.bookingId,
      );
    }

    _applyTrackingStatusToController();
  }

  void _applyTrackingStatusToController() {
    final trip = _activeTrip;
    final controller = _locationController;
    if (trip == null || controller == null) return;
    controller.updateTrackingStatus(_resolveTrackingStatus(trip));
  }

  /// Opens the update status screen inside a Modal Bottom Sheet.
  Future<void> _openUpdateStatusSheet(Trip trip) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: UpdateStatusPage(tripId: trip.id, initialTrip: trip),
              ),
            ],
          ),
        );
      },
    );

    if (updated == true && mounted) {
      await _loadActiveTrip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _activeTrip == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final error = _loadError;
    if (error != null && _activeTrip == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMedium),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loadActiveTrip,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final trip = _activeTrip;
    if (trip == null) return _buildNoActiveTripsPlaceholder();

    final isStarted =
        trip.status == 'Trip Started' ||
        trip.status == 'In Transit' ||
        trip.status == 'ONGOING' ||
        trip.status == 'SHIPMENT_START';
    final resolvedTrackingStatus = _resolveTrackingStatus(trip);
    final isTrackingEligible =
        resolvedTrackingStatus?.isLiveTrackingEligible ?? isStarted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = constraints.maxHeight * 0.66;

        return Column(
          children: [
            // 1. Live Map View (with red pointer & top status overlay)
            SizedBox(
              width: double.infinity,
              height: mapHeight,
              child: AnimatedBuilder(
                animation: _locationController ?? const _NoopListenable(),
                builder: (context, _) {
                  final controller = _locationController;
                  final position = controller?.currentPosition;
                  return LiveTrackingMap(
                    driverPosition: position == null
                        ? null
                        : LatLng(position.latitude, position.longitude),
                    pickupLabel: trip.pickupLocation,
                    dropLabel: trip.dropLocation,
                    isLive: controller?.isLiveTracking ?? false,
                    trackingStatusText:
                        resolvedTrackingStatus?.label ??
                        trip.trackingStatusLabel ??
                        trip.status,
                    statusMessage: _mapStatusMessage(
                      controller?.accessState ?? LocationAccessState.unknown,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  );
                },
              ),
            ),

            // 2. Details scrollview: Only live tracking indicator, customer, basic cargo, & change status button
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadActiveTrip,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Access Warning Banner if needed
                      AnimatedBuilder(
                        animation:
                            _locationController ?? const _NoopListenable(),
                        builder: (context, _) => _LocationAccessBanner(
                          state:
                              _locationController?.accessState ??
                              LocationAccessState.unknown,
                        ),
                      ),

                      // Beautiful Live Tracking In Progress Card (if status is ongoing / shipment started)
                      if (isTrackingEligible) ...[
                        _LiveTrackingToggleCard(
                          isEnabled: _isTrackingEnabled,
                          statusLabel:
                              resolvedTrackingStatus?.label ?? trip.status,
                          onToggleChanged: (value) {
                            setState(() => _isTrackingEnabled = value);
                            if (!value) {
                              _locationController?.dispose();
                              _locationController = null;
                            } else {
                              _handleActiveTrip(trip);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _StatusHistoryStrip(
                          statusLabel:
                              resolvedTrackingStatus?.label ?? trip.status,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Basic Cargo Detail
                      CargoMetricsRow(
                        cargoType: trip.cargoType,
                        weight: trip.weight,
                      ),
                      const SizedBox(height: 16),

                      // Customer Detail
                      CustomerContactCard(
                        customerName: trip.customerName,
                        customerPhone: trip.customerPhone,
                      ),
                      const SizedBox(height: 20),

                      // Button to change / update shipment status (opens Modal Bottom Sheet)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () => _openUpdateStatusSheet(trip),
                        icon: const Icon(Icons.edit_note_rounded, size: 24),
                        label: const Text(
                          'Change Shipment Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Explains, in a few words, why the driver's own pin isn't on the map yet.
  String _mapStatusMessage(LocationAccessState state) {
    switch (state) {
      case LocationAccessState.denied:
      case LocationAccessState.deniedForever:
        return 'Location off · showing route only';
      case LocationAccessState.serviceDisabled:
        return 'Device location off · showing route only';
      default:
        return 'Locating you…';
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final trip = _activeTrip;

    final String titleText;
    if (trip == null) {
      titleText = 'Live Tracking';
    } else if (trip.pickupLocation.isNotEmpty && trip.dropLocation.isNotEmpty) {
      titleText = '${trip.pickupLocation} → ${trip.dropLocation}';
    } else if (trip.pickupLocation.isNotEmpty) {
      titleText = trip.pickupLocation;
    } else {
      titleText = 'Trip In Progress';
    }

    return AppBar(
      backgroundColor: AppColors.navy,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        titleText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        if (trip != null) ...[
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                trip.bookingId,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoActiveTripsPlaceholder() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
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
              'No Active Shipment Loaded',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a Booking Order ID below to load shipment details, start live location tracking, and update status.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMedium),
            ),
            const SizedBox(height: 24),
            BookingIdEntryCard(onSubmit: _fetchTripForBookingId),
          ],
        ),
      ),
    );
  }
}

/// Animated Live Tracking Card displayed when shipment tracking is in progress.
class _LiveTrackingToggleCard extends StatefulWidget {
  final String statusLabel;
  final bool isEnabled;
  final ValueChanged<bool> onToggleChanged;

  const _LiveTrackingToggleCard({
    required this.statusLabel,
    required this.isEnabled,
    required this.onToggleChanged,
  });

  @override
  State<_LiveTrackingToggleCard> createState() =>
      __LiveTrackingToggleCardState();
}

class __LiveTrackingToggleCardState extends State<_LiveTrackingToggleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.4, end: 1.0).animate(_animController),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: AppColors.accentGreen,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.statusLabel.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.isEnabled ? 'LIVE' : 'PAUSED',
                        style: const TextStyle(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEnabled ? 'Tracking In Progress' : 'Tracking Paused',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isEnabled
                      ? 'Location updates are sent automatically every 30 minutes'
                      : 'Tap the switch to resume live tracking',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: widget.isEnabled,
            activeColor: AppColors.accentGreen,
            onChanged: widget.onToggleChanged,
          ),
        ],
      ),
    );
  }
}

class _StatusHistoryStrip extends StatelessWidget {
  final String statusLabel;

  const _StatusHistoryStrip({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    final steps = <String>['Started', 'In Transit', statusLabel];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isLast = index == steps.length - 1;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isLast ? AppColors.primary : AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isLast ? FontWeight.w700 : FontWeight.w600,
                      color: isLast ? AppColors.textDark : AppColors.textMedium,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isLast) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Lets [AnimatedBuilder] safely take a null [LocationTrackingController]
/// (before an active trip is known) without a special-cased builder.
class _NoopListenable extends Listenable {
  const _NoopListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _LocationAccessBanner extends StatelessWidget {
  final LocationAccessState state;

  const _LocationAccessBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final String? message;
    switch (state) {
      case LocationAccessState.denied:
        message =
            'Location permission is needed to share your live position. Tap to allow it.';
        break;
      case LocationAccessState.deniedForever:
        message =
            'Location permission was denied. Open Settings to enable it for live tracking.';
        break;
      case LocationAccessState.serviceDisabled:
        message = 'Turn on device location services to enable live tracking.';
        break;
      default:
        message = null;
    }

    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (state == LocationAccessState.serviceDisabled) {
              Geolocator.openLocationSettings();
            } else {
              Geolocator.openAppSettings();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.location_off_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
