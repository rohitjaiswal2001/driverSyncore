import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_trip_details_usecase.dart';
import '../../domain/usecases/update_trip_status_usecase.dart';
import '../../domain/usecases/get_quotes_usecase.dart';
import '../../domain/usecases/request_quote_usecase.dart';
import '../../domain/usecases/accept_quote_usecase.dart';
import '../../domain/usecases/get_quote_master_data_usecase.dart';
import '../../domain/usecases/create_booking_quote_usecase.dart';
import 'trips_event.dart';
import 'trips_state.dart';

class TripsBloc extends Bloc<TripsEvent, TripsState> {
  final GetTripDetailsUseCase getTripDetailsUseCase;
  final UpdateTripStatusUseCase updateTripStatusUseCase;
  final GetQuotesUseCase getQuotesUseCase;
  final RequestQuoteUseCase requestQuoteUseCase;
  final AcceptQuoteUseCase acceptQuoteUseCase;
  final GetQuoteMasterDataUseCase getQuoteMasterDataUseCase;
  final CreateBookingQuoteUseCase createBookingQuoteUseCase;

  TripsBloc({
    required this.getTripDetailsUseCase,
    required this.updateTripStatusUseCase,
    required this.getQuotesUseCase,
    required this.requestQuoteUseCase,
    required this.acceptQuoteUseCase,
    required this.getQuoteMasterDataUseCase,
    required this.createBookingQuoteUseCase,
  }) : super(TripsInitial()) {
    on<LoadTripDetails>(_onLoadTripDetails);
    on<UpdateTripStatus>(_onUpdateTripStatus);
    on<LoadQuotes>(_onLoadQuotes);
    on<RequestQuote>(_onRequestQuote);
    on<AcceptQuote>(_onAcceptQuote);
    on<FetchQuoteMasterData>(_onFetchQuoteMasterData);
    on<CreateBookingQuote>(_onCreateBookingQuote);
  }

  Future<void> _onLoadTripDetails(
    LoadTripDetails event,
    Emitter<TripsState> emit,
  ) async {
    emit(TripsLoading());
    try {
      final trip = await getTripDetailsUseCase(event.tripId);
      emit(TripDetailsLoaded(trip: trip));
    } catch (e) {
      emit(
        TripsError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onUpdateTripStatus(
    UpdateTripStatus event,
    Emitter<TripsState> emit,
  ) async {
    emit(TripsLoading());
    try {
      await updateTripStatusUseCase(
        UpdateTripStatusParams(tripId: event.tripId, status: event.status),
      );
      final updatedTrip = await getTripDetailsUseCase(event.tripId);
      emit(TripDetailsLoaded(trip: updatedTrip));
    } catch (e) {
      emit(
        TripsError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onLoadQuotes(LoadQuotes event, Emitter<TripsState> emit) async {
    emit(TripsLoading());
    try {
      final quotes = await getQuotesUseCase(status: event.status);
      emit(QuotesLoaded(quotes: quotes));
    } catch (e) {
      emit(
        TripsError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onRequestQuote(
    RequestQuote event,
    Emitter<TripsState> emit,
  ) async {
    emit(TripsLoading());
    try {
      final quote = await requestQuoteUseCase(event.quote);
      emit(QuoteActionSuccess(quote: quote));
    } catch (e) {
      emit(
        TripsError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onAcceptQuote(
    AcceptQuote event,
    Emitter<TripsState> emit,
  ) async {
    emit(TripsLoading());
    try {
      final quote = await acceptQuoteUseCase(event.quoteId);
      emit(QuoteActionSuccess(quote: quote));
    } catch (e) {
      emit(
        TripsError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onFetchQuoteMasterData(
    FetchQuoteMasterData event,
    Emitter<TripsState> emit,
  ) async {
    emit(QuoteMasterDataLoading());
    try {
      final masterData = await getQuoteMasterDataUseCase();
      emit(QuoteMasterDataLoaded(masterData: masterData));
    } catch (e) {
      emit(
        TripsError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onCreateBookingQuote(
    CreateBookingQuote event,
    Emitter<TripsState> emit,
  ) async {
    emit(TripsLoading());
    try {
      final quote = await createBookingQuoteUseCase(
        direction: event.direction,
        containerTypeId: event.containerTypeId,
        packagingId: event.packagingId,
        weightOfGoods: event.weightOfGoods,
        countryId: event.countryId,
        postalCode: event.postalCode,
        city: event.city,
        pickupDate: event.pickupDate,
        distanceKm: event.distanceKm,
        address: event.address,
        mobileNumber: event.mobileNumber,
      );
      emit(BookingQuoteCreated(quote: quote));
    } catch (e) {
      emit(
        TripsError(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }
}
