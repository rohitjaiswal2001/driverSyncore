import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/utils/reverse_geocoder.dart';
import '../../domain/entities/tracking_status.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import 'trip_completed_page.dart';

/// Lets the driver move a shipment through its tracking states.
///
/// The options come from the real `GET /tracking-statuses` endpoint rather
/// than a hardcoded workflow list, so the app always offers exactly the
/// states the backend recognises.
class UpdateStatusPage extends StatefulWidget {
  final String tripId;
  final Trip? initialTrip;

  /// Fires with the freshly fetched shipment right after a successful status
  /// update, so the screen behind this one can refresh without waiting for the
  /// sheet to close.
  final ValueChanged<Trip>? onStatusUpdated;

  const UpdateStatusPage({
    super.key,
    required this.tripId,
    this.initialTrip,
    this.onStatusUpdated,
  });

  @override
  State<UpdateStatusPage> createState() => _UpdateStatusPageState();
}

class _UpdateStatusPageState extends State<UpdateStatusPage> {
  Trip? _trip;
  List<TrackingStatus> _statuses = const [];
  TrackingStatus? _selected;

  /// Reason the driver gives when marking a shipment as failed.
  final _notesController = TextEditingController();
  final _notesFocus = FocusNode();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  /// A failed shipment must say why, so the fleet desk can act on it.
  bool get _requiresNotes => _selected?.isFailed ?? false;

  /// Accent for the step the shipment is on right now, distinct from the
  /// indigo used for the driver's pick and the green used for passed steps.
  static const _currentColor = AppColors.warning;

  @override
  void initState() {
    super.initState();
    _trip = widget.initialTrip;
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final repository = di.sl<TripsRepository>();
    try {
      final results = await Future.wait([
        repository.getTrackingStatuses(),
        repository.getTripDetails(widget.tripId),
      ]);

      if (!mounted) return;
      final allStatuses = results[0] as List<TrackingStatus>;
      final trip = results[1] as Trip;

      // Filter out PAUSE option from Update Status page as it is managed via the map toggle switch.
      // FAILED is hidden as well so drivers can't mark a trip failed from here.
      final statuses = allStatuses
          .where(
            (s) => s.code.toUpperCase() != 'PAUSE' && s.id != 6 && !s.isFailed,
          )
          .toList();

      setState(() {
        _statuses = statuses;
        _trip = trip;
        _selected = _defaultSelection(statuses, trip);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  bool _isSameStatus(TrackingStatus status, Trip trip) {
    if (trip.trackingStatusId != null &&
        trip.trackingStatusId! > 0 &&
        status.id == trip.trackingStatusId) {
      return true;
    }
    final tripCode = trip.trackingStatusCode?.trim().toUpperCase();
    final statusCode = status.code.trim().toUpperCase();
    if (tripCode != null && tripCode.isNotEmpty) {
      if (statusCode == tripCode) return true;
      if (statusCode.replaceAll('_', ' ') == tripCode.replaceAll('_', ' ')) {
        return true;
      }
    }
    final tripStatusText = trip.status.trim().toLowerCase();
    final statusLabelText = status.label.trim().toLowerCase();
    if (statusLabelText == tripStatusText) return true;
    final trackingLabel = trip.trackingStatusLabel?.trim().toLowerCase();
    if (trackingLabel != null && statusLabelText == trackingLabel) return true;

    return false;
  }

  TrackingStatus? _matchCurrent(List<TrackingStatus> statuses, Trip trip) {
    for (final status in statuses) {
      if (_isSameStatus(status, trip)) return status;
    }
    return null;
  }

  int _indexOfCurrent(List<TrackingStatus> statuses, Trip? trip) {
    if (trip == null) return -1;
    for (int i = 0; i < statuses.length; i++) {
      if (_isSameStatus(statuses[i], trip)) return i;
    }
    return -1;
  }

  int _getCurrentStatusIndex() => _indexOfCurrent(_statuses, _trip);

  /// The sheet opens on the step the driver is actually about to take - the
  /// one right after their current status - so the common case needs no tap.
  TrackingStatus? _defaultSelection(List<TrackingStatus> statuses, Trip trip) {
    if (trip.isShippingDone) return _matchCurrent(statuses, trip);
    final currentIndex = _indexOfCurrent(statuses, trip);
    if (currentIndex >= 0 && currentIndex + 1 < statuses.length) {
      return statuses[currentIndex + 1];
    }
    return _matchCurrent(statuses, trip);
  }

  /// The driver can only tap the immediate next status - their current one is
  /// shown highlighted but can't be picked. "Failed" is the exception: a
  /// shipment can fail from wherever it currently stands.
  bool _isSelectable(int index, int currentIndex) {
    if (_trip?.isShippingDone ?? false) return false;
    if (_statuses[index].isFailed) return true;
    if (currentIndex < 0) return true;
    return index == currentIndex + 1;
  }

  Future<void> _submit() async {
    final selected = _selected;
    final trip = _trip;
    if (selected == null || trip == null) return;
    if (trip.isShippingDone) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      double? lat;
      double? lng;
      String? address;
      try {
        final pos =
            await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              timeLimit: const Duration(seconds: 3),
            );
        lat = pos.latitude;
        lng = pos.longitude;
        // Same fix, turned into `area, district, state, country` for the API.
        address = await di.sl<ReverseGeocoder>().addressFor(lat, lng);
      } catch (_) {}

      await di.sl<TripsRepository>().updateTrackingStatus(
        orderId: trip.bookingId,
        statusId: selected.id,
        status: selected.code,
        latitude: lat,
        longitude: lng,
        address: address,
        notes: _notesController.text,
      );

      // Pull the shipment detail back immediately so this sheet and the screen
      // behind it both show the state the backend just recorded.
      Trip? refreshed;
      try {
        refreshed = await di.sl<TripsRepository>().getTripDetails(
          trip.bookingId,
        );
      } catch (_) {}

      if (!mounted) return;
      final freshTrip = refreshed;
      setState(() {
        _isSubmitting = false;
        if (freshTrip != null) {
          _trip = freshTrip;
          _selected = _defaultSelection(_statuses, freshTrip);
        }
      });
      if (freshTrip != null) widget.onStatusUpdated?.call(freshTrip);

      if (selected.isDone) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripCompletedPage(
              bookingId: trip.bookingId,
              transitTime: trip.dropEta,
              dropLocation: trip.dropLocation,
            ),
          ),
        );
        return;
      }

      TopSnackBar.show(
        context,
        message: 'Status updated to ${selected.label}',
        backgroundColor: AppColors.accentGreen,
        icon: Icons.check_circle_outline,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TopSnackBar.show(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lives inside a bottom sheet, so it gets a sheet-style header with a
    // close button instead of an app bar with a back arrow.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final trip = _trip;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
      // Held to the same column as the timeline below, so the close button
      // stays next to the title instead of at the far edge of an iPad.
      child: AdaptiveContainer(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update shipment status',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (trip != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Booking #${trip.bookingId}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
              ),
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textDark,
                size: 20,
              ),
            ),
          ],
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

    final error = _loadError;
    if (error != null && _statuses.isEmpty) {
      return Center(
        child: AdaptiveContainer.form(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.dangerBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Couldn't load statuses",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final trip = _trip;
    final currentIndex = _getCurrentStatusIndex();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: AdaptiveContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (trip != null) ...[
                    _buildRouteCard(trip),
                    const SizedBox(height: 16),
                  ],
                  if (trip != null && trip.isShippingDone) ...[
                    _buildCompletedBanner(),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionHeader(currentIndex),
                  const SizedBox(height: 10),
                  for (int i = 0; i < _statuses.length; i++)
                    _buildTimelineStep(_statuses[i], i, currentIndex),
                  if (_requiresNotes) ...[
                    const SizedBox(height: 8),
                    _buildFailureNotes(),
                  ],
                ],
              ),
            ),
          ),
        ),
        _buildSubmitBar(),
      ],
    );
  }

  Widget _buildFailureNotes() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.report_problem_outlined,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'What went wrong?',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your fleet manager needs a reason before they can act on a '
                  'failed shipment.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  focusNode: _notesFocus,
                  maxLines: 4,
                  minLines: 3,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Customer refused delivery, vehicle breakdown '
                        'near Ljubljana…',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textLight,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.danger,
                        width: 1.6,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
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

  /// Pickup → drop, with the same green/red dots the map uses for its pins.
  Widget _buildRouteCard(Trip trip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRouteEnd(
              label: 'PICKUP',
              place: trip.pickupLocation,
              dotColor: AppColors.accentGreen,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: _buildRouteEnd(
              label: 'DROP',
              place: trip.dropLocation,
              dotColor: AppColors.danger,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteEnd({
    required String label,
    required String place,
    required Color dotColor,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          place.isEmpty ? '—' : place,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This shipment is delivered. Status updates are locked.',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int currentIndex) {
    final total = _statuses.length;
    final isDone = _trip?.isShippingDone ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Shipment progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (currentIndex >= 0 && total > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Step ${currentIndex + 1} of $total',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
          ],
        ),
        if (!isDone) ...[
          const SizedBox(height: 4),
          const Text(
            'Status moves one step at a time. Pick the next step to move '
            'this shipment forward.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ],
    );
  }

  /// One row of the progress timeline: a node on a connecting rail, and the
  /// step itself. Only the immediate next step is a tappable card; passed,
  /// current and later steps are read-only.
  Widget _buildTimelineStep(
    TrackingStatus status,
    int index,
    int currentIndex,
  ) {
    final isFirst = index == 0;
    final isLast = index == _statuses.length - 1;
    final isCurrent = index == currentIndex;
    final isPast = currentIndex >= 0 && index < currentIndex;
    // The current status is never pickable - it has its own highlighted look.
    final isSelectable = !isCurrent && _isSelectable(index, currentIndex);
    final isSelected = isSelectable && _selected?.id == status.id;

    // A rail segment is "travelled" once the trip has moved past it.
    final topRailDone = currentIndex >= 0 && index <= currentIndex;
    final bottomRailDone = currentIndex >= 0 && index < currentIndex;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Expanded(
                  child: _buildRail(visible: !isFirst, done: topRailDone),
                ),
                _buildNode(
                  isPast: isPast,
                  isCurrent: isCurrent,
                  isSelectable: isSelectable,
                  isSelected: isSelected,
                ),
                Expanded(
                  child: _buildRail(visible: !isLast, done: bottomRailDone),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: isSelectable
                  ? _buildSelectableStep(status, isSelected: isSelected)
                  : _buildReadOnlyStep(
                      status,
                      index,
                      isPast: isPast,
                      isCurrent: isCurrent,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRail({required bool visible, required bool done}) {
    return Center(
      child: Container(
        width: 2.5,
        decoration: BoxDecoration(
          color: !visible
              ? Colors.transparent
              : done
              ? AppColors.accentGreen
              : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildNode({
    required bool isPast,
    required bool isCurrent,
    required bool isSelectable,
    required bool isSelected,
  }) {
    if (isPast) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.accentGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    }
    if (isCurrent) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _currentColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _currentColor.withValues(alpha: 0.3),
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.local_shipping_rounded,
          size: 16,
          color: Colors.white,
        ),
      );
    }
    if (isSelectable) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Icon(
          Icons.arrow_downward_rounded,
          size: 14,
          color: isSelected ? Colors.white : AppColors.primary,
        ),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
      ),
      child: const Icon(
        Icons.lock_rounded,
        size: 12,
        color: AppColors.textLight,
      ),
    );
  }

  /// The next step - the only one the driver can act on - as a radio card.
  Widget _buildSelectableStep(
    TrackingStatus status, {
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          HapticFeedback.selectionClick();
          _selected = status;
          // Don't carry a failure reason over to a non-failure status.
          if (!status.isFailed) {
            _notesController.clear();
            _notesFocus.unfocus();
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepTag('NEXT STEP', AppColors.primary),
                    const SizedBox(height: 6),
                    Text(
                      status.label,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected
                          ? 'Selected - tap the button below to confirm'
                          : 'Tap to select',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textLight,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isSelected ? 10 : 0,
                    height: isSelected ? 10 : 0,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Passed, current and locked steps: informative, not tappable.
  Widget _buildReadOnlyStep(
    TrackingStatus status,
    int index, {
    required bool isPast,
    required bool isCurrent,
  }) {
    final isDone = _trip?.isShippingDone ?? false;

    final String subtitle;
    final Color titleColor;
    final Color subtitleColor;
    if (isCurrent) {
      subtitle = isDone ? 'Shipment delivered' : 'Your shipment is here now';
      titleColor = AppColors.textDark;
      subtitleColor = _currentColor;
    } else if (isPast) {
      subtitle = 'Completed';
      titleColor = AppColors.textMedium;
      subtitleColor = AppColors.success;
    } else {
      subtitle = index > 0
          ? 'Unlocks after ${_statuses[index - 1].label}'
          : 'Locked';
      titleColor = AppColors.textLight;
      subtitleColor = AppColors.textLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: isCurrent
          ? BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _currentColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent) _buildStepTag('CURRENT', _currentColor),
        ],
      ),
    );
  }

  Widget _buildStepTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSubmitBar() {
    // A failed shipment cannot be submitted without a reason.
    final hasReasonIfNeeded =
        !_requiresNotes || _notesController.text.trim().isNotEmpty;
    final isDone = _trip?.isShippingDone ?? false;
    final selected = _selected;
    final canSubmit =
        !isDone &&
        selected != null &&
        !_isSubmitting &&
        hasReasonIfNeeded &&
        _trip != null &&
        !_isSameStatus(selected, _trip!);

    // Finishing the trip is the moment worth celebrating, so it goes green.
    final isFinalStep = canSubmit && selected.isDone;
    final buttonColor = isDone || isFinalStep
        ? AppColors.accentGreen
        : AppColors.primary;

    final String label;
    if (isDone) {
      label = 'Shipment completed';
    } else if (canSubmit) {
      label = 'Update status';
    } else {
      label = 'Select the next step';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: AdaptiveContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDone) ...[
              const Row(
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    size: 14,
                    color: AppColors.textLight,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your current location is attached to this update.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDone
                    ? AppColors.accentGreen.withValues(alpha: 0.8)
                    : AppColors.primary.withValues(alpha: 0.35),
                disabledForegroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: canSubmit ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDone || isFinalStep
                              ? Icons.check_circle_rounded
                              : Icons.arrow_circle_right_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
