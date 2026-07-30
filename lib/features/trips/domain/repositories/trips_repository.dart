import '../entities/trip.dart';
import '../entities/quote.dart';
import '../entities/dashboard_data.dart';
import '../entities/tracking_status.dart';
import '../../data/models/booking_models.dart';

abstract class TripsRepository {
  Future<DashboardData> getDashboardData();
  Future<Trip> getTripDetails(String tripId);
  Future<Trip> updateTripStatus({required String tripId, required String status});

  /// The fixed set of live-tracking session states (NOT_STARTED,
  /// SHIPMENT_START, ONGOING, SHIPPING_DONE, FAILED).
  Future<List<TrackingStatus>> getTrackingStatuses();

  /// Best-effort location ping sent every ~10s while a trip is live-tracking
  /// eligible. Never throws - a failed ping should not interrupt the driver.
  Future<void> pingTrackingLocation({
    required String orderId,
    required double latitude,
    required double longitude,
    String? address,
    String? notes,
    String status = 'ONGOING',
    int? statusId,
  });

  /// Driver-initiated tracking status change. Unlike [pingTrackingLocation]
  /// this surfaces failures, because the driver is explicitly waiting on it.
  Future<void> updateTrackingStatus({
    required String orderId,
    required int statusId,
    String? status,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
  });


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
