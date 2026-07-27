import '../../domain/entities/trip.dart';

class TripModel extends Trip {
  const TripModel({
    required super.id,
    required super.bookingId,
    required super.status,
    required super.isNew,
    required super.customerName,
    required super.customerPhone,
    required super.cargoType,
    required super.weight,
    required super.truckInfo,
    required super.truckType,
    required super.pickupLocation,
    required super.pickupAddress,
    required super.pickupDate,
    required super.dropLocation,
    required super.dropAddress,
    required super.dropEta,
    required super.distanceRemainingKm,
    required super.etaHours,
    required super.currentLocation,
    required super.arrivalRequirementText,
    required super.routePoints,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      status: json['status'] as String,
      isNew: json['isNew'] as bool? ?? false,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      cargoType: json['cargoType'] as String,
      weight: json['weight'] as String,
      truckInfo: json['truckInfo'] as String,
      truckType: json['truckType'] as String,
      pickupLocation: json['pickupLocation'] as String,
      pickupAddress: json['pickupAddress'] as String,
      pickupDate: json['pickupDate'] as String,
      dropLocation: json['dropLocation'] as String,
      dropAddress: json['dropAddress'] as String,
      dropEta: json['dropEta'] as String,
      distanceRemainingKm: (json['distanceRemainingKm'] as num).toDouble(),
      etaHours: (json['etaHours'] as num).toDouble(),
      currentLocation: json['currentLocation'] as String,
      arrivalRequirementText: json['arrivalRequirementText'] as String,
      routePoints: List<String>.from(json['routePoints'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'status': status,
      'isNew': isNew,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'cargoType': cargoType,
      'weight': weight,
      'truckInfo': truckInfo,
      'truckType': truckType,
      'pickupLocation': pickupLocation,
      'pickupAddress': pickupAddress,
      'pickupDate': pickupDate,
      'dropLocation': dropLocation,
      'dropAddress': dropAddress,
      'dropEta': dropEta,
      'distanceRemainingKm': distanceRemainingKm,
      'etaHours': etaHours,
      'currentLocation': currentLocation,
      'arrivalRequirementText': arrivalRequirementText,
      'routePoints': routePoints,
    };
  }
}
