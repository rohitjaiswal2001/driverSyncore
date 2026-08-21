import 'package:equatable/equatable.dart';

class Trip extends Equatable {
  final String id;
  final String bookingId;
  final String
  status; // Assigned, Completed, Reached Pickup, Loaded, Trip Started, In Transit, Reached Destination, Delivered
  final bool isNew;
  final String customerName;
  final String customerPhone;
  final String cargoType;
  final String weight;
  final String truckInfo;
  final String truckType; // e.g. "14 Ft Truck"
  final String pickupLocation;
  final String pickupAddress;
  final String pickupDate;
  final String dropLocation;
  final String dropAddress;
  final String dropEta;

  /// Transit time for the shipment, straight from `shipment-details`
  /// (`transit_time`). A server-formatted display string - rendered as-is,
  /// never reformatted here. Null when the backend has not set one yet.
  final String? transitTime;

  final double distanceRemainingKm;
  final double etaHours;
  final String currentLocation;
  final String arrivalRequirementText;
  final List<String> routePoints;

  /// Live-tracking session state for this shipment (NOT_STARTED,
  /// SHIPMENT_START, ONGOING, SHIPPING_DONE, FAILED) - distinct from [status],
  /// the free-text workflow label. Null for trips the tracking API hasn't
  /// reported on yet (e.g. local mock data).
  final String? trackingStatusCode;
  final String? trackingStatusLabel;
  final int? trackingStatusId;

  /// Shipment direction from the booking ('import' or 'export'). Null when
  /// the source data doesn't carry it (e.g. a booking-quote-derived trip).
  final String? direction;

  /// Fully-qualified URL to the booking PDF, resolved from the shipment
  /// -details response. Null when no document has been generated yet.
  final String? documentUrl;

  /// Optional failure reason or status notes returned from the backend.
  final String notes;

  /// Optional timestamp/date when the shipment was marked completed or delivered.
  final String? completedDate;

  /// Returns clean YYYY-MM-DD date string for completed shipment date or fallback pickup date.
  String get formattedCompletedDate {
    final raw = (completedDate != null && completedDate!.trim().isNotEmpty)
        ? completedDate!.trim()
        : pickupDate.trim();
    if (raw.isEmpty) return '';
    if (raw.contains('T')) return raw.split('T')[0];
    if (raw.contains(' ')) return raw.split(' ')[0];
    return raw;
  }

  /// True if live tracking has started for this shipment (tracking status code is not NOT_STARTED).
  bool get isTrackingStarted {
    if (trackingStatusCode != null && trackingStatusCode!.isNotEmpty) {
      return trackingStatusCode != 'NOT_STARTED';
    }
    if (trackingStatusLabel != null && trackingStatusLabel!.isNotEmpty) {
      return trackingStatusLabel!.toLowerCase() != 'not started';
    }
    final norm = status.trim().toLowerCase();
    return norm == 'trip started' ||
        norm == 'in transit' ||
        norm == 'ongoing' ||
        norm == 'shipment_start' ||
        norm == 'reached pickup' ||
        norm == 'loaded' ||
        norm == 'reached destination' ||
        norm == 'completed' ||
        norm == 'delivered';
  }

  /// True if the shipment is completed/delivered and status updates are locked.
  bool get isShippingDone {
    if (trackingStatusCode != null &&
        trackingStatusCode!.toUpperCase() == 'SHIPPING_DONE') {
      return true;
    }
    if (trackingStatusId == 4) {
      return true;
    }
    final trackingNorm = (trackingStatusLabel ?? '').trim().toLowerCase();
    if (trackingNorm == 'shipping done' ||
        trackingNorm == 'completed' ||
        trackingNorm == 'delivered') {
      return true;
    }
    final norm = status.trim().toLowerCase();
    return norm == 'shipping done' ||
        norm == 'completed' ||
        norm == 'delivered';
  }

  const Trip({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.isNew,
    required this.customerName,
    required this.customerPhone,
    required this.cargoType,
    required this.weight,
    required this.truckInfo,
    required this.truckType,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.pickupDate,
    required this.dropLocation,
    required this.dropAddress,
    required this.dropEta,
    this.transitTime,
    required this.distanceRemainingKm,
    required this.etaHours,
    required this.currentLocation,
    required this.arrivalRequirementText,
    required this.routePoints,
    this.trackingStatusCode,
    this.trackingStatusLabel,
    this.trackingStatusId,
    this.direction,
    this.documentUrl,
    this.completedDate,
    this.notes = '',
  });

  Trip copyWith({
    String? id,
    String? bookingId,
    String? status,
    bool? isNew,
    String? customerName,
    String? customerPhone,
    String? cargoType,
    String? weight,
    String? truckInfo,
    String? truckType,
    String? pickupLocation,
    String? pickupAddress,
    String? pickupDate,
    String? dropLocation,
    String? dropAddress,
    String? dropEta,
    String? transitTime,
    double? distanceRemainingKm,
    double? etaHours,
    String? currentLocation,
    String? arrivalRequirementText,
    List<String>? routePoints,
    String? trackingStatusCode,
    String? trackingStatusLabel,
    int? trackingStatusId,
    String? direction,
    String? documentUrl,
    String? completedDate,
  }) {
    return Trip(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      status: status ?? this.status,
      isNew: isNew ?? this.isNew,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      cargoType: cargoType ?? this.cargoType,
      weight: weight ?? this.weight,
      truckInfo: truckInfo ?? this.truckInfo,
      truckType: truckType ?? this.truckType,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupDate: pickupDate ?? this.pickupDate,
      dropLocation: dropLocation ?? this.dropLocation,
      dropAddress: dropAddress ?? this.dropAddress,
      dropEta: dropEta ?? this.dropEta,
      transitTime: transitTime ?? this.transitTime,
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      etaHours: etaHours ?? this.etaHours,
      currentLocation: currentLocation ?? this.currentLocation,
      arrivalRequirementText:
          arrivalRequirementText ?? this.arrivalRequirementText,
      routePoints: routePoints ?? this.routePoints,
      trackingStatusCode: trackingStatusCode ?? this.trackingStatusCode,
      trackingStatusLabel: trackingStatusLabel ?? this.trackingStatusLabel,
      trackingStatusId: trackingStatusId ?? this.trackingStatusId,
      direction: direction ?? this.direction,
      documentUrl: documentUrl ?? this.documentUrl,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bookingId,
    status,
    isNew,
    customerName,
    customerPhone,
    cargoType,
    weight,
    truckInfo,
    truckType,
    pickupLocation,
    pickupAddress,
    pickupDate,
    dropLocation,
    dropAddress,
    dropEta,
    transitTime,
    distanceRemainingKm,
    etaHours,
    currentLocation,
    arrivalRequirementText,
    routePoints,
    trackingStatusCode,
    trackingStatusLabel,
    trackingStatusId,
    direction,
    documentUrl,
    completedDate,
  ];
}
