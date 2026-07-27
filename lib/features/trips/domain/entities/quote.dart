import 'package:equatable/equatable.dart';

class Quote extends Equatable {
  final String id;
  final String quoteId;
  final String price;
  final String route;
  final String vehicleType;
  final String date;
  final String status; // Pending, Accepted
  final String pickupLocation;
  final String dropLocation;
  final String mobileNumber;
  final String address;
  final String city;
  final String country;
  final String postalCode;
  final String packagingType;
  final String weight;
  final int? distanceKm;
  final String? transitTime;

  const Quote({
    required this.id,
    required this.quoteId,
    required this.price,
    required this.route,
    required this.vehicleType,
    required this.date,
    required this.status,
    required this.pickupLocation,
    required this.dropLocation,
    required this.mobileNumber,
    required this.address,
    required this.city,
    required this.country,
    required this.postalCode,
    required this.packagingType,
    required this.weight,
    this.distanceKm,
    this.transitTime,
  });

  Quote copyWith({
    String? id,
    String? quoteId,
    String? price,
    String? route,
    String? vehicleType,
    String? date,
    String? status,
    String? pickupLocation,
    String? dropLocation,
    String? mobileNumber,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    String? packagingType,
    String? weight,
    int? distanceKm,
    String? transitTime,
  }) {
    return Quote(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      price: price ?? this.price,
      route: route ?? this.route,
      vehicleType: vehicleType ?? this.vehicleType,
      date: date ?? this.date,
      status: status ?? this.status,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      packagingType: packagingType ?? this.packagingType,
      weight: weight ?? this.weight,
      distanceKm: distanceKm ?? this.distanceKm,
      transitTime: transitTime ?? this.transitTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        quoteId,
        price,
        route,
        vehicleType,
        date,
        status,
        pickupLocation,
        dropLocation,
        mobileNumber,
        address,
        city,
        country,
        postalCode,
        packagingType,
        weight,
        distanceKm,
        transitTime,
      ];
}
