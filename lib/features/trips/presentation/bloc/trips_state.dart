import 'package:equatable/equatable.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/quote.dart';
import '../../data/models/booking_models.dart';

abstract class TripsState extends Equatable {
  const TripsState();

  @override
  List<Object?> get props => [];
}

class TripsInitial extends TripsState {}

class TripsLoading extends TripsState {}

class TripsLoaded extends TripsState {
  final List<Trip> trips;

  const TripsLoaded({required this.trips});

  @override
  List<Object?> get props => [trips];
}

class TripDetailsLoaded extends TripsState {
  final Trip trip;

  const TripDetailsLoaded({required this.trip});

  @override
  List<Object?> get props => [trip];
}

class QuotesLoaded extends TripsState {
  final List<Quote> quotes;

  const QuotesLoaded({required this.quotes});

  @override
  List<Object?> get props => [quotes];
}

class QuoteActionSuccess extends TripsState {
  final Quote quote;

  const QuoteActionSuccess({required this.quote});

  @override
  List<Object?> get props => [quote];
}

class QuoteMasterDataLoading extends TripsState {}

class QuoteMasterDataLoaded extends TripsState {
  final QuoteMasterData masterData;

  const QuoteMasterDataLoaded({required this.masterData});

  @override
  List<Object?> get props => [masterData];
}

class BookingQuoteCreated extends TripsState {
  final Quote quote;

  const BookingQuoteCreated({required this.quote});

  @override
  List<Object?> get props => [quote];
}

class TripsError extends TripsState {
  final String errorMessage;

  const TripsError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
