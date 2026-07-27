import '../entities/trip.dart';
import '../entities/quote.dart';
import '../entities/dashboard_data.dart';
import '../../data/models/booking_models.dart';

abstract class TripsRepository {
  Future<DashboardData> getDashboardData();
  Future<List<Trip>> getTrips({required String role});
  Future<Trip> getTripDetails(String tripId);
  Future<Trip> updateTripStatus({required String tripId, required String status});
  
  Future<List<Quote>> getQuotes({String? status});
  Future<Quote> requestQuote(Quote quote);
  Future<Quote> acceptQuote(String quoteId);

  Future<QuoteMasterData> getQuoteMasterData();
  Future<Quote> createBookingQuote({
    required String direction,
    required int containerTypeId,
    required int packagingId,
    required int weightOfGoods,
    required int countryId,
    required String postalCode,
    required String city,
    required String pickupDate,
    required int distanceKm,
    required String address,
    required String mobileNumber,
  });
}
