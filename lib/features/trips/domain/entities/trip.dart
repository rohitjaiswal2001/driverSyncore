import 'package:equatable/equatable.dart';

class Trip extends Equatable {
  final String id;
  final String bookingId;
  final String status; // Assigned, Completed, Reached Pickup, Loaded, Trip Started, In Transit, Reached Destination, Delivered
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
  final double distanceRemainingKm;
  final double etaHours;
  final String currentLocation;
  final String arrivalRequirementText;
  final List<String> routePoints;

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
    required this.distanceRemainingKm,
    required this.etaHours,
    required this.currentLocation,
    required this.arrivalRequirementText,
    required this.routePoints,
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
    double? distanceRemainingKm,
    double? etaHours,
    String? currentLocation,
    String? arrivalRequirementText,
    List<String>? routePoints,
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
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      etaHours: etaHours ?? this.etaHours,
      currentLocation: currentLocation ?? this.currentLocation,
      arrivalRequirementText: arrivalRequirementText ?? this.arrivalRequirementText,
      routePoints: routePoints ?? this.routePoints,
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
        distanceRemainingKm,
        etaHours,
        currentLocation,
        arrivalRequirementText,
        routePoints,
      ];
}
