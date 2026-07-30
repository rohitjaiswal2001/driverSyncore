import 'package:equatable/equatable.dart';

/// One entry from `GET /tracking-statuses` — the fixed set of states a
/// shipment's live-tracking session can be in (distinct from the driver's
/// free-text workflow status like "Loaded" or "Reached Pickup").
class TrackingStatus extends Equatable {
  static const codeNotStarted = 'NOT_STARTED';
  static const codeShipmentStart = 'SHIPMENT_START';
  static const codeOngoing = 'ONGOING';
  static const codeShippingDone = 'SHIPPING_DONE';
  static const codeFailed = 'FAILED';

  final int id;
  final String code;
  final String label;

  const TrackingStatus({required this.id, required this.code, required this.label});

  factory TrackingStatus.fromJson(Map<String, dynamic> json) {
    return TrackingStatus(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  /// Only while the trip is starting or actively moving should the app send
  /// live location pings — not before the driver starts, and not once the
  /// shipment is done or has failed.
  bool get isLiveTrackingEligible => code == codeShipmentStart || code == codeOngoing;

  bool get isFailed => code == codeFailed;
  bool get isDone => code == codeShippingDone;
  bool get isNotStarted => code == codeNotStarted;

  @override
  List<Object?> get props => [id, code, label];
}
