import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/tracking_status.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/booking_models.dart';
import '../models/dashboard_model.dart';

class TripsRepositoryImpl implements TripsRepository {
  final ApiClient _apiClient;

  TripsRepositoryImpl(this._apiClient);

  @override
  Future<DashboardData> getDashboardData() async {
    try {
      final response = await _apiClient.get(ApiConstants.dashboard);
      final responseData = response.data;
      if (responseData != null && responseData is Map<String, dynamic> && responseData['status'] == true) {
        return DashboardModel.fromJson(responseData);
      }
      final errorMessage = (responseData is Map<String, dynamic> 
          ? responseData['message'] 
          : null) ?? 'Failed to load dashboard data';
      throw Exception(errorMessage);
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
  @override
  Future<Trip> getTripDetails(String tripId) async {
    final cleanId = tripId.trim();
    try {
      final response = await _apiClient.get(
        ApiConstants.shipmentDetails,
        queryParameters: {'order_id': cleanId},
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData['status'] == true) {
          return _mapShipmentDetailsToTrip(responseData, cleanId);
        }
        final msg = responseData['message']?.toString() ??
            'Shipment not found for this order ID.';
        throw Exception(msg);
      }
      throw Exception('Shipment not found for this order ID.');
    } on AppException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception:')) {
        rethrow;
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Trip _mapShipmentDetailsToTrip(
    Map<String, dynamic> responseJson,
    String requestedOrderId,
  ) {
    final data = responseJson['data'] as Map<String, dynamic>? ?? {};
    final trackingList = responseJson['tracking_history'] as List? ?? [];
    Map<String, dynamic>? trackingFirst;
    if (trackingList.isNotEmpty && trackingList[0] is Map<String, dynamic>) {
      trackingFirst = trackingList[0] as Map<String, dynamic>;
    }

    final containerType = data['container_type'] as Map<String, dynamic>?;
    final packaging = data['packaging'] as Map<String, dynamic>?;
    final country = data['country'] as Map<String, dynamic>?;
    final user = data['user'] as Map<String, dynamic>?;
    final statusObj = trackingFirst?['status'] as Map<String, dynamic>?;
    final bidStatus = data['bid_status'] as Map<String, dynamic>?;

    final orderId = data['order_id']?.toString() ?? requestedOrderId;
    final statusLabel = statusObj?['label']?.toString() ??
        bidStatus?['label']?.toString() ??
        'Unknown';

    final firstName = user?['first_name']?.toString() ?? '';
    final lastName = user?['last_name']?.toString() ?? '';
    final custName = ('$firstName $lastName').trim();
    final custPhone = user?['phone']?.toString() ?? '';

    final cargo = packaging?['name']?.toString() ??
        data['title']?.toString() ??
        'General Cargo';
    final weightVal =
        data['weight_of_goods'] != null ? '${data['weight_of_goods']} KG' : '';
    final containerName = containerType?['name']?.toString();
    final truckTypeVal = containerName != null ? '$containerName Container' : '';

    final pickupLoc = data['pickup_location']?.toString() ?? '';
    final addressVal = data['address']?.toString() ?? '';
    final cityVal = data['city']?.toString() ?? '';
    final countryVal = country?['name']?.toString() ?? '';
    final fullPickupAddress =
        [addressVal, cityVal, countryVal].where((s) => s.isNotEmpty).join(', ');

    final dropLoc = data['drop_location']?.toString() ?? '';
    final dropEtaVal = data['transit_time']?.toString() ?? '';
    final distKm = double.tryParse(data['distance_km']?.toString() ?? '') ?? 0.0;

    final trackingStatusId = statusObj?['id'] is int
        ? statusObj!['id'] as int
        : int.tryParse('${statusObj?['id']}');

    final documentUrl = _resolveDocumentUrl(
      pdfUrl: responseJson['pdf_url']?.toString(),
      pdfPath: data['pdf_path']?.toString(),
    );

    return Trip(
      id: orderId,
      bookingId: orderId,
      status: statusLabel,
      isNew: false,
      customerName: custName,
      customerPhone: custPhone,
      cargoType: cargo,
      weight: weightVal,
      truckInfo: truckTypeVal,
      truckType: truckTypeVal,
      pickupLocation: pickupLoc,
      pickupAddress: fullPickupAddress.isEmpty ? pickupLoc : fullPickupAddress,
      pickupDate: data['pickup_date']?.toString() ?? '',
      dropLocation: dropLoc,
      dropAddress: dropLoc,
      dropEta: dropEtaVal,
      distanceRemainingKm: distKm,
      etaHours: 0.0,
      currentLocation:
          trackingFirst?['current_location']?.toString() ?? pickupLoc,
      arrivalRequirementText: data['title']?.toString() ?? '',
      trackingStatusId: trackingStatusId,
      trackingStatusCode: statusObj?['code']?.toString(),
      trackingStatusLabel: statusObj?['label']?.toString(),
      direction: data['direction']?.toString(),
      documentUrl: documentUrl,
      routePoints: [pickupLoc, dropLoc],
    );
  }

  /// The API sometimes returns a ready-to-use `pdf_url`; when it doesn't,
  /// derive one from `pdf_path` using the storage host confirmed against the
  /// staging API (note: no `/public` segment, unlike the API's own base URL).
  String? _resolveDocumentUrl({String? pdfUrl, String? pdfPath}) {
    if (pdfUrl != null && pdfUrl.trim().isNotEmpty) return pdfUrl.trim();
    if (pdfPath == null || pdfPath.trim().isEmpty) return null;

    final apiBase = Uri.parse(ApiConstants.baseUrl);
    final storageBase = apiBase.replace(
      path: apiBase.path.replaceFirst(RegExp(r'/public/api/?$'), '/storage'),
    );
    return '$storageBase/${pdfPath.trim()}';
  }

  @override
  Future<Trip> updateTripStatus({
    required String tripId,
    required String status,
  }) async {
    // No confirmed write endpoint exists yet for this granular workflow
    // status (distinct from the tracking-status enum backing live tracking -
    // see ApiConstants.updateTrackingStatus). Re-fetch the real trip and
    // apply the change locally so the UI reflects the driver's intent without
    // fabricating a persisted server state.
    final trip = await getTripDetails(tripId);
    return trip.copyWith(
      status: status,
      distanceRemainingKm:
          status == 'Completed' || status == 'Delivered' ? 0.0 : null,
      etaHours: status == 'Completed' || status == 'Delivered' ? 0.0 : null,
      isNew: false,
    );
  }

  List<TrackingStatus>? _cachedTrackingStatuses;

  @override
  Future<List<TrackingStatus>> getTrackingStatuses() async {
    final cached = _cachedTrackingStatuses;
    if (cached != null) return cached;

    try {
      final response = await _apiClient.get(ApiConstants.trackingStatuses);
      final responseData = response.data;
      if (responseData is Map<String, dynamic> && responseData['status'] == true) {
        final list = responseData['data'] as List? ?? [];
        final statuses = list
            .whereType<Map<String, dynamic>>()
            .map(TrackingStatus.fromJson)
            .toList();
        _cachedTrackingStatuses = statuses;
        return statuses;
      }
      final errorMessage = (responseData is Map<String, dynamic>
          ? responseData['message']
          : null) ?? 'Failed to load tracking statuses';
      throw Exception(errorMessage);
    } on AppException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception:')) {
        rethrow;
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> pingTrackingLocation({
    required String orderId,
    required double latitude,
    required double longitude,
    String? address,
    String? notes,
    String status = 'ONGOING',
    int? statusId,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.updateTrackingStatus,
        data: {
          'order_id': orderId,
          'latitude': latitude,
          'longitude': longitude,
          if (address != null && address.trim().isNotEmpty)
            'address': address.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          'status': status,
          // ignore: use_null_aware_elements
          if (statusId != null) 'tracking_status_id': statusId,
        },
      );
    } catch (_) {
      // Swallowed - best-effort telemetry ping
    }
  }

  @override
  Future<void> updateTrackingStatus({
    required String orderId,
    required int statusId,
    String? status,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.updateTrackingStatus,
        data: {
          'order_id': orderId,
          'tracking_status_id': statusId,
          'status': status ?? 'ONGOING',
          // ignore: use_null_aware_elements
          if (latitude != null) 'latitude': latitude,
          // ignore: use_null_aware_elements
          if (longitude != null) 'longitude': longitude,
          if (address != null && address.trim().isNotEmpty)
            'address': address.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['status'] == false) {
        throw Exception(
          responseData['message']?.toString() ??
              'Failed to update tracking status',
        );
      }
    } on AppException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception && e.toString().startsWith('Exception:')) rethrow;
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Client-side cache populated only by real API responses (getQuotes,
  // requestQuote, createBookingQuote) - never seeded with placeholder data.
  static final List<Quote> _mockQuotes = [];

  @override
  Future<List<Quote>> getQuotes({String? status}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null && status != 'All' && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      final response = await _apiClient.get(
        ApiConstants.confirmBooking,
        queryParameters: queryParams,
      );
      final responseData = response.data;
      if (responseData != null && responseData is Map<String, dynamic> && responseData['status'] == true) {
        final list = responseData['data'] as List? ?? [];
        return list.map((item) => mapBookingItemToQuote(item as Map<String, dynamic>)).toList();
      }
      final errorMessage = (responseData is Map<String, dynamic> 
          ? responseData['message'] 
          : null) ?? 'Failed to load quotes';
      throw Exception(errorMessage);
    } on AppException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Quote> requestQuote(Quote quote) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Generate a fresh unique quote ID
    final nextIdNum = 12 + _mockQuotes.length;
    final generatedQuoteId = 'QT-2026-00$nextIdNum';
    
    final newQuote = quote.copyWith(
      id: generatedQuoteId,
      quoteId: generatedQuoteId,
      status: 'Pending',
      date: '24 Jun 2026', // Mock date
    );
    
    _mockQuotes.insert(0, newQuote); // Insert at beginning of list
    return newQuote;
  }

  @override
  Future<Quote> acceptQuote(String quoteId) async {
    // 1. Hit the real API
    final response = await _apiClient.post(
      ApiConstants.confirmBooking,
      data: {
        'booking_id': int.tryParse(quoteId) ?? 0,
      },
    );

    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      final success = responseData['status'] ?? responseData['success'];
      if (success == false) {
        throw Exception(responseData['message'] ?? 'Failed to confirm booking');
      }
    }

    // Update the local cache (populated only from real API responses) so the
    // quotes tab reflects the change immediately.
    final index = _mockQuotes.indexWhere((q) => q.quoteId == quoteId);
    if (index != -1) {
      final updatedQuote = _mockQuotes[index].copyWith(status: 'Accepted');
      _mockQuotes[index] = updatedQuote;
      return updatedQuote;
    }

    throw Exception('Quote $quoteId not found');
  }

  @override
  Future<QuoteMasterData> getQuoteMasterData() async {
    try {
      final response = await _apiClient.get(ApiConstants.quoteData);
      if (response.data != null && response.data['status'] == true) {
        return QuoteMasterData.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load master data');
    } catch (e) {
      throw Exception('Failed to load master data: $e');
    }
  }

  @override
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
  }) async {
    try {
      final requestData = {
        'direction': direction,
        'container_type_id': containerTypeId,
        'packaging_id': packagingId,
        'weight_of_goods': weightOfGoods,
        'country_id': countryId,
        'postal_code': postalCode,
        'city': city,
        'pickup_date': pickupDate,
        'distance_km': distanceKm,
        'address': address,
      };
      final response = await _apiClient.post(
        ApiConstants.bookingQuote,
        data: requestData,
      );
      final responseData = response.data;
      if (responseData != null && responseData is Map<String, dynamic> && responseData['status'] == true) {
        final quote = mapBookingQuoteResponseToQuote(
          responseData,
          address,
          mobileNumber,
        );
        // Insert into mockQuotes list so it appears in the quotes tab
        _mockQuotes.insert(0, quote);
        return quote;
      }
      final errorMessage = (responseData is Map<String, dynamic> 
          ? responseData['message'] 
          : null) ?? 'Failed to generate quote';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
