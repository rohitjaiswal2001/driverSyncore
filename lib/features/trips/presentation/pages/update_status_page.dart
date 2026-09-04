import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
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

      // Filter out PAUSE option from Update Status page as it is managed via the map toggle switch
      final statuses = allStatuses
          .where((s) => s.code.toUpperCase() != 'PAUSE' && s.id != 6)
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

  /// The driver can tap their current status or the immediate next one -
  /// picking the current one just leaves Update disabled. "Failed" is the
  /// exception: a shipment can fail from wherever it currently stands.
  bool _isSelectable(int index, int currentIndex) {
    if (_trip?.isShippingDone ?? false) return false;
    if (_statuses[index].isFailed) return true;
    if (currentIndex < 0) return true;
    return index == currentIndex || index == currentIndex + 1;
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
      ),
      body: _buildBody(),
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
                onPressed: _load,
                child: const Text('Retry'),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trip != null) ...[
                  _buildTripSummary(trip),
                  const SizedBox(height: 20),
                ],
                if (trip != null && trip.isShippingDone) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accentGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.accentGreen,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Shipping Completed: This shipment is delivered and status updates are locked.',
                            style: TextStyle(
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Text(
                  'SELECT NEW STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Status moves one step at a time - you can only move to the '
                  'next status, or mark the trip Failed.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMedium),
                ),
                const SizedBox(height: 14),
                for (int i = 0; i < _statuses.length; i++)
                  _buildStatusOption(_statuses[i], i, currentIndex),
                if (_requiresNotes) _buildFailureNotes(),
              ],
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

  Widget _buildTripSummary(Trip trip) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Booking ID',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                ' #${trip.bookingId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    TrackingStatus status,
    int index,
    int currentIndex,
  ) {
    final isSelected = _selected?.id == status.id;
    final isCurrent = index == currentIndex;
    final isPast = currentIndex >= 0 && index < currentIndex;

    final isLocked = !_isSelectable(index, currentIndex);
    // Everything the driver cannot reach in one step reads as locked: the
    // statuses already passed, the one they are on, and anything beyond next.
    final isMuted = isLocked && !isCurrent;

    return GestureDetector(
      onTap: isLocked
          ? null
          : () => setState(() {
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isMuted ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isMuted
                ? AppColors.border.withValues(alpha: 0.5)
                : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPast ? AppColors.accentGreen : Colors.transparent,
                border: Border.all(
                  color: isPast
                      ? AppColors.accentGreen
                      : isSelected
                      ? AppColors.primary
                      : isMuted
                      ? const Color(0xFFCBD5E1)
                      : AppColors.textLight,
                  width: 2,
                ),
              ),
              child: Center(
                child: isPast
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
                      )
                    : isMuted
                    ? const Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: Color(0xFF94A3B8),
                      )
                    : Container(
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
            Expanded(
              child: Text(
                status.label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isSelected || isCurrent
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: isMuted
                      ? const Color(0xFF94A3B8)
                      : isSelected
                      ? AppColors.primary
                      : AppColors.textDark,
                ),
              ),
            ),
            if (isCurrent)
              _buildStatusBadge(
                'CURRENT',
                background: AppColors.primaryLight,
                foreground: AppColors.primary,
              )
            else if (isPast)
              _buildStatusBadge(
                'PASSED',
                background: AppColors.accentGreen.withValues(alpha: 0.12),
                foreground: AppColors.accentGreen,
              )
            else if (isMuted)
              _buildStatusBadge(
                'LOCKED',
                background: const Color(0xFFF1F5F9),
                foreground: const Color(0xFF94A3B8),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    String text, {
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: foreground,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildSubmitBar() {
    // A failed shipment cannot be submitted without a reason.
    final hasReasonIfNeeded =
        !_requiresNotes || _notesController.text.trim().isNotEmpty;
    final isDone = _trip?.isShippingDone ?? false;
    final canSubmit =
        !isDone &&
        _selected != null &&
        !_isSubmitting &&
        hasReasonIfNeeded &&
        _trip != null &&
        !_isSameStatus(_selected!, _trip!);

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
          backgroundColor: isDone ? AppColors.accentGreen : AppColors.primary,
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
                  Text(
                    isDone ? 'Shipping Completed' : 'Update',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isDone ? Icons.check_circle : Icons.check_circle_outline,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }
}
