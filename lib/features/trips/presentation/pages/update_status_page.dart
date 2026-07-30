import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
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

  const UpdateStatusPage({super.key, required this.tripId, this.initialTrip});

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
      final statuses = results[0] as List<TrackingStatus>;
      final trip = results[1] as Trip;

      setState(() {
        _statuses = statuses;
        _trip = trip;
        _selected = _matchCurrent(statuses, trip);
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

  TrackingStatus? _matchCurrent(List<TrackingStatus> statuses, Trip trip) {
    final code = trip.trackingStatusCode;
    if (code == null) return null;
    for (final status in statuses) {
      if (status.code == code) return status;
    }
    return null;
  }

  Future<void> _submit() async {
    final selected = _selected;
    final trip = _trip;
    if (selected == null || trip == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      await di.sl<TripsRepository>().updateTrackingStatus(
        orderId: trip.bookingId,
        statusId: selected.id,
        notes: _notesController.text,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

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
                  const SizedBox(height: 24),
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
                const SizedBox(height: 12),
                for (final status in _statuses) _buildStatusOption(status),
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
                'BOOKING ID',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                trip.bookingId,
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

  Widget _buildStatusOption(TrackingStatus status) {
    final isSelected = _selected?.id == status.id;
    final isCurrent = _trip?.trackingStatusCode == status.code;

    return GestureDetector(
      onTap: () => setState(() {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textLight,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                status.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textDark,
                ),
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CURRENT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMedium,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBar() {
    // A failed shipment cannot be submitted without a reason.
    final hasReasonIfNeeded =
        !_requiresNotes || _notesController.text.trim().isNotEmpty;
    final canSubmit =
        _selected != null &&
        !_isSubmitting &&
        hasReasonIfNeeded &&
        _selected?.code != _trip?.trackingStatusCode;

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
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Update',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle_outline, size: 20),
                ],
              ),
      ),
    );
  }
}
