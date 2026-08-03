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
import '../../../../core/widgets/app_info_sheet.dart';
import '../../../../core/widgets/skeleton_box.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc_extensions.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../widgets/active_trip_card.dart';
import '../widgets/booking_id_entry_card.dart';
import '../widgets/dashboard_quick_action_grid.dart';
import '../widgets/driver_greeting_header.dart';
import 'trip_details_page.dart';

class DriverDashboardPage extends StatefulWidget {
  final String username;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToTracking;
  final VoidCallback onNavigateToOrders;

  const DriverDashboardPage({
    super.key,
    required this.username,
    required this.onNavigateToProfile,
    required this.onNavigateToTracking,
    required this.onNavigateToOrders,
  });

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  String? _activeBookingId;
  Trip? _activeTrip;
  User? _cachedUser;

  bool _isLoadingOrder = false;
  String? _orderErrorMessage;

  /// True until the saved booking order (if any) has been restored, so the page
  /// never flashes the "enter a booking ID" card at a driver who already has an
  /// active trip.
  bool _isRestoringTrip = true;

  DateTime? _lastBackPressedAt;

  @override
  void initState() {
    super.initState();

    // Render immediately from whatever the bloc already holds, then refresh.
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
  // Data
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingOrder = false;
        _orderErrorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Pull-to-refresh: reloads the driver profile and the active shipment.
  Future<void> _handleRefresh() async {
    final bookingId = _activeTrip?.bookingId ?? _activeBookingId;

    await Future.wait<void>([
      // A profile failure already surfaces through the bloc; it must not stop
      // the trip from refreshing.
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
    setState(() {
      _activeBookingId = null;
      _activeTrip = null;
      _orderErrorMessage = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

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
      onConfirmAsync: () async {
        try {
          await di.sl<LogoutUseCase>()();
        } catch (_) {}
      },
    );

    if (shouldLogout && mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _launch(Uri uri, String failureMessage) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      TopSnackBar.show(
        context,
        message: failureMessage,
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline,
      );
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

  void _openContactSheet() {
    final trip = _activeTrip;
    final customerPhone = trip?.customerPhone.trim() ?? '';

    final actions = <AppSheetAction>[
      if (trip != null && customerPhone.isNotEmpty)
        AppSheetAction(
          icon: Icons.person_outline_rounded,
          label: 'Customer · ${trip.customerName}',
          value: customerPhone,
          color: AppColors.customerAccent,
          onTap: _callCustomer,
        ),
      if (AppInfo.hasSupportPhone)
        AppSheetAction(
          icon: Icons.headset_mic_rounded,
          label: 'Fleet desk',
          value: AppInfo.supportPhone,
          color: AppColors.accentGreen,
          onTap: () => _launch(
            Uri(scheme: 'tel', path: AppInfo.supportPhone),
            'No phone app available on this device.',
          ),
        ),
      if (AppInfo.hasSupportEmail)
        AppSheetAction(
          icon: Icons.mail_outline_rounded,
          label: 'Email support',
          value: AppInfo.supportEmail,
          color: AppColors.accentBlue,
          onTap: () => _launch(
            Uri(scheme: 'mailto', path: AppInfo.supportEmail),
            'No mail app available on this device.',
          ),
        ),
    ];

    showAppInfoSheet(
      context,
      icon: Icons.headset_mic_rounded,
      title: 'Contact',
      message: actions.isEmpty
          ? 'No contact is available right now. Load a Booking Order to reach '
                'its customer, or contact your fleet manager directly.'
          : 'Reach the people involved in your current shipment.',
      accentColor: actions.isEmpty ? AppColors.accentOrange : AppColors.primary,
      actions: actions,
    );
  }

  void _openUploadDocs() {
    showAppInfoSheet(
      context,
      icon: Icons.article_rounded,
      title: 'Upload Documents',
      message:
          'Uploading PODs, e-way bills and trip sheets from the app is coming '
          'in a future update. For now, hand documents to your fleet manager.',
      accentColor: AppColors.accentOrange,
    );
  }

  Future<void> _openTripDetails() async {
    final trip = _activeTrip;
    if (trip == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailsPage(tripId: trip.id, initialTrip: trip),
      ),
    );

    // The status may have been advanced from the details page.
    if (mounted) {
      await _fetchTripForBookingId(trip.bookingId, saveToPrefs: false);
    }
  }

  /// Requires a second back press within two seconds before leaving the app, so
  /// a stray gesture mid-trip does not close the dashboard.
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

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  String _getSalutation() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

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
            backgroundColor: AppColors.surface,
            appBar: _buildAppBar(user),
            body: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  DriverGreetingHeader(
                    salutation: _getSalutation(),
                    name: driverName,
                  ),
                  const SizedBox(height: 20),

                  _buildTripSection(),
                  const SizedBox(height: 26),

                  // DashboardQuickActionGrid(
                  //   actions: [
                  //     QuickAction(
                  //       icon: Icons.article_rounded,
                  //       label: 'Upload Docs',
                  //       color: AppColors.accentPurple,
                  //       badge: 'SOON',
                  //       onTap: _openUploadDocs,
                  //     ),
                  //     QuickAction(
                  //       icon: Icons.headset_mic_rounded,
                  //       label: 'Contact',
                  //       color: AppColors.accentGreen,
                  //       onTap: _openContactSheet,
                  //     ),
                  //     QuickAction(
                  //       icon: Icons.route_rounded,
                  //       label: 'My Trips',
                  //       color: AppColors.accentBlue,
                  //       onTap: widget.onNavigateToOrders,
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 32),
                  Center(
                    child: Text(
                      '${AppInfo.appName} v${AppInfo.version}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(User? user) {
    final fullName = user != null && user.firstName.trim().isNotEmpty
        ? '${user.firstName} ${user.lastName ?? ''}'.trim()
        : (widget.username.trim().isNotEmpty
              ? widget.username.trim()
              : 'Driver');
    final company = user?.companyName.trim() ?? '';
    final subtitle = company.isNotEmpty ? company : 'Driver';

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Semantics(
        button: true,
        label: 'Open profile',
        child: InkWell(
          onTap: widget.onNavigateToProfile,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Stack(
                  children: [
                    UserAvatar(
                      name: fullName,
                      imageUrl: user?.profileImage,
                      radius: 21,
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
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user == null)
                        const SkeletonBox(width: 130, height: 15)
                      else
                        Text(
                          fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: -0.3,
                          ),
                        ),
                      const SizedBox(height: 3),
                      if (user == null)
                        const SkeletonBox(width: 90, height: 11)
                      else
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Semantics(
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
        ),
      ],
    );
  }

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
          children: [
            const Text(
              'ACTIVE TRIP',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textMedium,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 10),
            if (_isLoadingOrder)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: AppColors.textMedium,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ActiveTripCard(
          trip: trip,
          onViewDetails: _openTripDetails,
          onTrackMap: widget.onNavigateToTracking,
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

/// Inline banner for a failed background refresh, shown under the trip card so
/// the still-valid cached trip stays visible.
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
