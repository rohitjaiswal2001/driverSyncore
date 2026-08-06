import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/active_order_store.dart';
import '../../../../core/utils/recent_orders_store.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc_extensions.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/tracking_status.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../bloc/trips_bloc.dart';
import '../bloc/trips_event.dart';
import '../controllers/location_tracking_controller.dart';
import '../widgets/active_trip_card.dart';
import '../widgets/booking_id_entry_card.dart';
import 'trip_details_page.dart';

class DriverDashboardPage extends StatefulWidget {
  final String username;
  final VoidCallback onNavigateToProfile;

  /// Handed the dashboard's own tracking controller so the tracking page can
  /// adopt it instead of spinning up a second one for the same order.
  final void Function(LocationTrackingController? controller)
  onNavigateToTracking;

  const DriverDashboardPage({
    super.key,
    required this.username,
    required this.onNavigateToProfile,
    required this.onNavigateToTracking,
  });

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  String? _activeBookingId;
  Trip? _activeTrip;
  User? _cachedUser;
  LocationTrackingController? _dashboardLocationController;

  bool _isLoadingOrder = false;
  String? _orderErrorMessage;
  bool _isRestoringTrip = true;

  DateTime? _lastBackPressedAt;

  @override
  void dispose() {
    _dashboardLocationController?.dispose();
    super.dispose();
  }

  void _syncDashboardLocationTracking(Trip trip) {
    if (_dashboardLocationController?.orderId != trip.bookingId) {
      _dashboardLocationController?.dispose();
      _dashboardLocationController = LocationTrackingController(
        repository: di.sl<TripsRepository>(),
        orderId: trip.bookingId,
      );
    }
    final code = trip.trackingStatusCode ?? '';
    final label = trip.trackingStatusLabel;
    final isLive =
        code == 'SHIPMENT_START' || code == 'ONGOING' || trip.isTrackingStarted;
    if (isLive) {
      _dashboardLocationController?.updateTrackingStatus(
        TrackingStatus(
          id: trip.trackingStatusId ?? 3,
          code: code.isNotEmpty ? code : 'ONGOING',
          label: label ?? 'Ongoing',
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    final currentState = context.read<AuthBloc>().state;
    if (currentState is AuthSuccess) {
      _cachedUser = currentState.user;
    }

    _restoreActiveBooking();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthBloc>().add(const GetProfileDetails());
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Data Logic
  // ---------------------------------------------------------------------------

  Future<void> _restoreActiveBooking() async {
    final savedBookingId = di.sl<ActiveOrderStore>().read();

    if (savedBookingId != null) {
      _activeBookingId = savedBookingId;
      await _fetchTripForBookingId(savedBookingId, saveToPrefs: false);
    }

    if (mounted) setState(() => _isRestoringTrip = false);
  }

  Future<void> _fetchTripForBookingId(
    String bookingId, {
    bool saveToPrefs = true,
  }) async {
    setState(() {
      _isLoadingOrder = true;
      _orderErrorMessage = null;
    });

    try {
      final trip = await di.sl<TripsRepository>().getTripDetails(bookingId);

      if (saveToPrefs) {
        await di.sl<ActiveOrderStore>().set(bookingId);
      }
      await di.sl<RecentOrdersStore>().record(trip.bookingId);

      if (!mounted) return;
      setState(() {
        _activeBookingId = trip.bookingId;
        _activeTrip = trip;
        _isLoadingOrder = false;
      });
      _syncDashboardLocationTracking(trip);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingOrder = false;
        _orderErrorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleRefresh() async {
    final bookingId = _activeTrip?.bookingId ?? _activeBookingId;

    await Future.wait<void>([
      context.read<AuthBloc>().refreshProfile().catchError((_) {}),
      if (bookingId != null && bookingId.trim().isNotEmpty)
        _fetchTripForBookingId(bookingId, saveToPrefs: false),
    ]);
  }

  Future<void> _changeBookingOrder() async {
    final confirmed = await showAppConfirmDialog(
      context,
      icon: Icons.swap_horiz_rounded,
      title: 'Change booking order?',
      message:
          'Your current shipment will be cleared from this dashboard so you '
          'can load a different Booking Order ID. The trip itself is not '
          'cancelled.',
      confirmLabel: 'Change',
      accentColor: AppColors.navy,
      accentBackground: AppColors.primaryLight,
    );

    if (!confirmed) return;

    await di.sl<ActiveOrderStore>().clear();
    if (!mounted) return;
    _clearActiveOrderState();
  }

  void _clearActiveOrderState() {
    setState(() {
      _activeBookingId = null;
      _activeTrip = null;
      _orderErrorMessage = null;
    });
  }

  /// Hands the live controller to the tracking page. Letting that page build
  /// its own controller for the same order would run a second position stream
  /// and a second ping timer, double-posting every location update.
  void _openTracking() =>
      widget.onNavigateToTracking(_dashboardLocationController);

  Future<void> _confirmLogout() async {
    final shouldLogout = await showAppConfirmDialog(
      context,
      icon: Icons.logout_rounded,
      title: 'Log out?',
      message:
          'You will need to sign in again to view your trips and update '
          'shipment status.',
      confirmLabel: 'Log out',
      accentColor: AppColors.danger,
      accentBackground: AppColors.dangerBg,
    );

    if (shouldLogout && mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  void _callCustomer() {
    final phone = _activeTrip?.customerPhone.trim() ?? '';
    if (phone.isEmpty) return;
    _launch(
      Uri(scheme: 'tel', path: phone),
      'No phone app available on this device.',
    );
  }

  Future<void> _launch(Uri uri, String failureMessage) async {
    if (!mounted) return;
    try {
      final can = await canLaunchUrl(uri);
      if (can) {
        await launchUrl(uri);
      } else if (mounted) {
        TopSnackBar.show(
          context,
          message: failureMessage,
          backgroundColor: AppColors.danger,
          icon: Icons.error_outline,
        );
      }
    } catch (_) {}
  }

  Future<void> _openTripDetails() async {
    final trip = _activeTrip;
    if (trip == null) return;

    context.read<TripsBloc>().add(LoadTripDetails(tripId: trip.id));

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailsPage(tripId: trip.id, initialTrip: trip),
      ),
    );

    if (!mounted) return;

    // The trip stack can clear the active order on the way back (completing a
    // shipment, then "Clear Order"), so re-read the store rather than assuming
    // the order that was open when we left is still the active one.
    final storedBookingId = di.sl<ActiveOrderStore>().read();
    if (storedBookingId == null) {
      _clearActiveOrderState();
    } else {
      await _fetchTripForBookingId(storedBookingId, saveToPrefs: false);
    }
  }

  void _handleBackPressed() {
    final now = DateTime.now();
    final isConfirming =
        _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) < const Duration(seconds: 2);

    if (isConfirming) {
      TopSnackBar.dismiss();
      SystemNavigator.pop();
      return;
    }

    _lastBackPressedAt = now;
    TopSnackBar.show(
      context,
      message: 'Press back again to exit',
      backgroundColor: AppColors.navy,
      icon: Icons.exit_to_app_rounded,
      duration: const Duration(seconds: 2),
    );
  }

  String _getSalutation() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            setState(() => _cachedUser = state.user);
          } else if (state is AuthLoggingOut) {
            // Emitted before the token is cleared, so the ping timer stops
            // while it can still authenticate - waiting for this page to be
            // unmounted would let a tick fire against a stripped header.
            _dashboardLocationController?.stopTracking();
          }
        },
        builder: (context, state) {
          final user = _cachedUser;
          final driverName = user != null && user.firstName.trim().isNotEmpty
              ? user.firstName.trim()
              : (widget.username.trim().isNotEmpty
                    ? widget.username.trim()
                    : 'Driver');

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                // Integrated Dark Navy Header AppBar
                _buildHeader(user, driverName),

                // Main Content List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppColors.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        20,
                        16,
                        24 + MediaQuery.of(context).padding.bottom,
                      ),
                      children: [
                        // Active Trip / Booking Section
                        _buildTripSection(),
                        const SizedBox(height: 28),

                        // Footer Branding
                        Center(
                          child: Text(
                            '${AppInfo.appName} v${AppInfo.version}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(User? user, String driverName) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.navyDeep],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x331E1B4B),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: widget.onNavigateToProfile,
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          UserAvatar(
                            name: driverName,
                            imageUrl: user?.profileImage,
                            radius: 24,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.navy,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_getSalutation()},',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$driverName!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Log out',
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _confirmLogout,
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.logout_rounded,
                          color: AppColors.danger,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /*
  // ---------------------------------------------------------------------------
  // Quick Shortcuts (Commented Out per design spec)
  // ---------------------------------------------------------------------------
  Widget _buildQuickShortcuts() {
    return Row(
      children: [
        Expanded(
          child: _buildShortcutCard(
            title: 'Live Tracking',
            subtitle: 'GPS Navigation',
            icon: Icons.navigation_rounded,
            iconColor: AppColors.accentGreen,
            bgColor: AppColors.accentGreen.withValues(alpha: 0.12),
            onTap: _openTracking,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildShortcutCard(
            title: 'My Profile',
            subtitle: 'Account Settings',
            icon: Icons.person_rounded,
            iconColor: AppColors.primary,
            bgColor: AppColors.primaryLight,
            onTap: widget.onNavigateToProfile,
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  */

  Widget _buildTripSection() {
    if (_isRestoringTrip) return const _TripCardSkeleton();

    final trip = _activeTrip;
    if (trip == null) {
      return BookingIdEntryCard(
        onSubmit: _fetchTripForBookingId,
        isLoading: _isLoadingOrder,
        errorMessage: _orderErrorMessage,
        initialValue: _activeBookingId,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ACTIVE SHIPMENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isLoadingOrder)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _changeBookingOrder();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Change Booking ID',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ActiveTripCard(
          trip: trip,
          onViewDetails: _openTripDetails,
          onTrackMap: _openTracking,
          onChangeBooking: _changeBookingOrder,
          onCallCustomer: _callCustomer,
        ),
        if (_orderErrorMessage != null) ...[
          const SizedBox(height: 12),
          _RefreshErrorBanner(
            message: _orderErrorMessage!,
            onRetry: _isLoadingOrder
                ? null
                : () => _fetchTripForBookingId(
                    trip.bookingId,
                    saveToPrefs: false,
                  ),
          ),
        ],
      ],
    );
  }
}

/// Placeholder shown while the saved booking order is being restored.
class _TripCardSkeleton extends StatelessWidget {
  const _TripCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(
                width: 96,
                height: 26,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              SkeletonBox(
                width: 88,
                height: 26,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ],
          ),
          SizedBox(height: 22),
          SkeletonBox(width: 70, height: 10),
          SizedBox(height: 8),
          SkeletonBox(width: 150, height: 15),
          SizedBox(height: 24),
          SkeletonBox(width: 96, height: 10),
          SizedBox(height: 8),
          SkeletonBox(width: 176, height: 15),
          SizedBox(height: 22),
          SkeletonBox(
            height: 68,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SkeletonBox(
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SkeletonBox(
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inline banner for a failed background refresh, shown under the trip card.
class _RefreshErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _RefreshErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sync_problem_rounded,
            size: 18,
            color: AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Couldn't refresh: $message",
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                foregroundColor: AppColors.danger,
              ),
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
