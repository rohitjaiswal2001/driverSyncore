import 'package:equatable/equatable.dart';
import '../../domain/entities/quote.dart';

abstract class TripsEvent extends Equatable {
  const TripsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrips extends TripsEvent {
  final String role;

  const LoadTrips({required this.role});

  @override
  List<Object?> get props => [role];
}

class LoadTripDetails extends TripsEvent {
  final String tripId;

  const LoadTripDetails({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

class UpdateTripStatus extends TripsEvent {
  final String tripId;
  final String status;

  const UpdateTripStatus({required this.tripId, required this.status});

  @override
  List<Object?> get props => [tripId, status];
}

class LoadQuotes extends TripsEvent {
  final String? status;

  const LoadQuotes({this.status});

  @override
  List<Object?> get props => [status];
}

class RequestQuote extends TripsEvent {
  final Quote quote;

  const RequestQuote({required this.quote});

  @override
  List<Object?> get props => [quote];
}

class AcceptQuote extends TripsEvent {
  final String quoteId;

  const AcceptQuote({required this.quoteId});

  @override
  List<Object?> get props => [quoteId];
}

class FetchQuoteMasterData extends TripsEvent {
  const FetchQuoteMasterData();
}

class CreateBookingQuote extends TripsEvent {
  final String direction;
  final int containerTypeId;
  final int packagingId;
  final int weightOfGoods;
  final int countryId;
  final String postalCode;
  final String city;
  final String pickupDate;
  final int distanceKm;
  final String address;
  final String mobileNumber;

  const CreateBookingQuote({
    required this.direction,
    required this.containerTypeId,
    required this.packagingId,
    required this.weightOfGoods,
    required this.countryId,
    required this.postalCode,
    required this.city,
    required this.pickupDate,
    required this.distanceKm,
    required this.address,
    required this.mobileNumber,
  });

  @override
  List<Object?> get props => [
    direction,
    containerTypeId,
    packagingId,
    weightOfGoods,
    countryId,
    postalCode,
    city,
    pickupDate,
    distanceKm,
    address,
    mobileNumber,
  ];
}
