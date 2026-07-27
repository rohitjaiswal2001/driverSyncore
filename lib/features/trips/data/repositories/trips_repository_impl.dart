import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/dashboard_data.dart';
import '../models/trip_model.dart';
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
  // In-memory mock list of trips to make status changes fully interactive
  final List<Trip> _mockTrips = [
    const TripModel(
      id: 'BK-2026-10024',
      bookingId: 'BK-2026-10024',
      status: 'Assigned',
      isNew: true,
      customerName: 'Rahul Sharma',
      customerPhone: '+91 9876543210',
      cargoType: 'Furniture',
      weight: '500 KG',
      truckInfo: 'MH01AB1234 - 14 Ft Truck',
      truckType: '14 Ft Truck',
      pickupLocation: 'To Koper Warehouse',
      pickupAddress: 'To Koper, Maharashtra',
      pickupDate: '20 Jun 2026, 10:00 AM',
      dropLocation: 'Caspian Sea',
      dropAddress: 'Okhla',
      dropEta: '21 Jun 2026, 11:00 PM',
      distanceRemainingKm: 850.0,
      etaHours: 12.0,
      currentLocation: 'Nashik, Maharashtra',
      arrivalRequirementText: 'Arrival required in 45 minutes',
      routePoints: [
        'To Koper Warehouse, MH',
        'Nashik, Maharashtra',
        'Caspian Sea',
      ],
    ),
    const TripModel(
      id: 'BK-2026-10031',
      bookingId: 'BK-2026-10031',
      status: 'In Transit',
      isNew: false,
      customerName: 'Ankit Verma',
      customerPhone: '+91 9988776655',
      cargoType: 'Industrial Machinery',
      weight: '3200 KG',
      truckInfo: 'GJ05CD4321 - 20 Ft Container',
      truckType: '20 Ft Container',
      pickupLocation: 'Surat Industrial Hub',
      pickupAddress: 'Hazira, Surat, Gujarat',
      pickupDate: '22 Jun 2026, 07:00 AM',
      dropLocation: 'Chennai Port',
      dropAddress: 'Kattupalli Port, Tamil Nadu',
      dropEta: '24 Jun 2026, 06:00 PM',
      distanceRemainingKm: 420.0,
      etaHours: 6.5,
      currentLocation: 'Hyderabad, Telangana',
      arrivalRequirementText: 'Port gate closes at 8 PM',
      routePoints: [
        'Surat Industrial Hub',
        'Pune Bypass',
        'Hyderabad',
        'Chennai Port',
      ],
    ),
    const TripModel(
      id: 'BK-2026-10038',
      bookingId: 'BK-2026-10038',
      status: 'Assigned',
      isNew: true,
      customerName: 'Priya Mehta',
      customerPhone: '+91 7654321098',
      cargoType: 'Perishable Goods',
      weight: '800 KG',
      truckInfo: 'RJ14MN9876 - Refrigerated Van',
      truckType: 'Van',
      pickupLocation: 'Jaipur Cold Storage',
      pickupAddress: 'Sitapura Industrial Area, Jaipur',
      pickupDate: '24 Jun 2026, 05:00 AM',
      dropLocation: 'Delhi INA Market',
      dropAddress: 'INA Colony, New Delhi',
      dropEta: '24 Jun 2026, 01:00 PM',
      distanceRemainingKm: 270.0,
      etaHours: 4.0,
      currentLocation: 'Jaipur, Rajasthan',
      arrivalRequirementText: 'Refrigeration must be maintained at 4°C',
      routePoints: [
        'Jaipur Cold Storage',
        'Alwar, Rajasthan',
        'Delhi INA Market',
      ],
    ),
    const TripModel(
      id: 'BK-2026-10045',
      bookingId: 'BK-2026-10045',
      status: 'Assigned',
      isNew: true,
      customerName: 'Amit Singhania',
      customerPhone: '+91 9988771122',
      cargoType: 'Chemical Drums',
      weight: '4500 KG',
      truckInfo: 'HR55XY9988 - 20 Ft Container',
      truckType: '20 Ft Container',
      pickupLocation: 'Gurugram Sector 34',
      pickupAddress: 'Sector 34 Industrial Area, Gurugram, Haryana',
      pickupDate: '25 Jun 2026, 09:00 AM',
      dropLocation: 'Kolkata Port',
      dropAddress: 'Kidderpore, Kolkata, West Bengal',
      dropEta: '28 Jun 2026, 05:00 PM',
      distanceRemainingKm: 1450.0,
      etaHours: 24.0,
      currentLocation: 'Gurugram Sector 34',
      arrivalRequirementText: 'Hazmat handling certification required',
      routePoints: [
        'Gurugram Sector 34',
        'Varanasi Bypass',
        'Kolkata Port',
      ],
    ),
    const TripModel(
      id: 'BK-2026-10052',
      bookingId: 'BK-2026-10052',
      status: 'Assigned',
      isNew: true,
      customerName: 'Vikram Singh',
      customerPhone: '+91 9543210987',
      cargoType: 'Agricultural Produce',
      weight: '2200 KG',
      truckInfo: 'PB10CZ5544 - 14 Ft Truck',
      truckType: '14 Ft Truck',
      pickupLocation: 'Ludhiana Mandi',
      pickupAddress: 'Gill Road Grain Market, Ludhiana, Punjab',
      pickupDate: '26 Jun 2026, 06:00 AM',
      dropLocation: 'Mumbai JNPT',
      dropAddress: 'JN Port, Nhava Sheva, Maharashtra',
      dropEta: '29 Jun 2026, 10:00 AM',
      distanceRemainingKm: 1380.0,
      etaHours: 22.0,
      currentLocation: 'Ludhiana Mandi',
      arrivalRequirementText: 'Ventilation must be kept open',
      routePoints: [
        'Ludhiana Mandi',
        'Delhi Bypass',
        'Ahmedabad Ring Road',
        'Mumbai JNPT',
      ],
    ),
    const TripModel(
      id: 'BK-2026-10060',
      bookingId: 'BK-2026-10060',
      status: 'Assigned',
      isNew: true,
      customerName: 'Sanjay Kumar',
      customerPhone: '+91 8899001122',
      cargoType: 'Electronics Components',
      weight: '650 KG',
      truckInfo: 'KA03ZZ7788 - Refrigerated Van',
      truckType: 'Van',
      pickupLocation: 'Bangalore Electronic City',
      pickupAddress: 'Phase 1, Electronic City, Bengaluru',
      pickupDate: '27 Jun 2026, 02:00 PM',
      dropLocation: 'Hyderabad Gachibowli',
      dropAddress: 'DLF Cyber City, Gachibowli, Hyderabad',
      dropEta: '28 Jun 2026, 04:00 AM',
      distanceRemainingKm: 570.0,
      etaHours: 8.0,
      currentLocation: 'Bangalore Electronic City',
      arrivalRequirementText: 'ESD protected transport mandatory',
      routePoints: [
        'Bangalore Electronic City',
        'Anantapur Bypass',
        'Hyderabad Gachibowli',
      ],
    ),
    const TripModel(
      id: 'BK-2026-09412',
      bookingId: 'BK-2026-09412',
      status: 'Completed',
      isNew: false,
      customerName: 'Suresh Patel',
      customerPhone: '+91 9123456789',
      cargoType: 'Electronic Goods',
      weight: '1200 KG',
      truckInfo: 'DL01ZA5678 - 20 Ft Container',
      truckType: '20 Ft Container',
      pickupLocation: 'Mumbai Port',
      pickupAddress: 'JNPT, Navi Mumbai',
      pickupDate: '15 Jun 2026, 08:00 AM',
      dropLocation: 'Delhi Warehouse',
      dropAddress: 'Okhla Phase III, Delhi',
      dropEta: '17 Jun 2026, 04:00 PM',
      distanceRemainingKm: 0.0,
      etaHours: 0.0,
      currentLocation: 'Delhi Warehouse',
      arrivalRequirementText: 'Delivered on time',
      routePoints: [
        'Mumbai Port',
        'Surat',
        'Jaipur',
        'Delhi Warehouse',
      ],
    ),
    const TripModel(
      id: 'BK-2026-09205',
      bookingId: 'BK-2026-09205',
      status: 'Delivered',
      isNew: false,
      customerName: 'Nirmala Krishnan',
      customerPhone: '+91 8012345678',
      cargoType: 'Textiles',
      weight: '950 KG',
      truckInfo: 'TN07PQ1122 - 14 Ft Truck',
      truckType: '14 Ft Truck',
      pickupLocation: 'Coimbatore Mills',
      pickupAddress: 'Peelamedu, Coimbatore, TN',
      pickupDate: '10 Jun 2026, 09:00 AM',
      dropLocation: 'Bangalore Garments Hub',
      dropAddress: 'Peenya Industrial Area, Bengaluru',
      dropEta: '11 Jun 2026, 03:00 PM',
      distanceRemainingKm: 0.0,
      etaHours: 0.0,
      currentLocation: 'Bangalore Garments Hub',
      arrivalRequirementText: 'Delivered ahead of schedule',
      routePoints: [
        'Coimbatore Mills',
        'Salem',
        'Bangalore Garments Hub',
      ],
    ),
    const TripModel(
      id: 'BK-2026-09118',
      bookingId: 'BK-2026-09118',
      status: 'Completed',
      isNew: false,
      customerName: 'Deepak Joshi',
      customerPhone: '+91 9321654870',
      cargoType: 'Auto Parts',
      weight: '1800 KG',
      truckInfo: 'MP09RS3344 - 20 Ft Container',
      truckType: '20 Ft Container',
      pickupLocation: 'Pithampur Auto Zone',
      pickupAddress: 'Pithampur, Madhya Pradesh',
      pickupDate: '05 Jun 2026, 06:30 AM',
      dropLocation: 'Pune Auto Cluster',
      dropAddress: 'Chakan, Pune, Maharashtra',
      dropEta: '06 Jun 2026, 08:00 AM',
      distanceRemainingKm: 0.0,
      etaHours: 0.0,
      currentLocation: 'Pune Auto Cluster',
      arrivalRequirementText: 'All parts received intact',
      routePoints: [
        'Pithampur Auto Zone',
        'Indore',
        'Nashik',
        'Pune Auto Cluster',
      ],
    ),
  ];

  @override
  Future<List<Trip>> getTrips({required String role}) async {
    // Simulate minor network delay
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockTrips;
  }

  @override
  Future<Trip> getTripDetails(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockTrips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      return _mockTrips[index];
    }
    throw Exception('Trip with ID $tripId not found');
  }

  @override
  Future<Trip> updateTripStatus({
    required String tripId,
    required String status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _mockTrips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      // Create updated trip and replace in list
      final updatedTrip = _mockTrips[index].copyWith(
        status: status,
        // If status becomes Completed, set remaining distance to 0, etc.
        distanceRemainingKm: status == 'Completed' || status == 'Delivered' ? 0.0 : null,
        etaHours: status == 'Completed' || status == 'Delivered' ? 0.0 : null,
        isNew: false,
      );
      _mockTrips[index] = updatedTrip;
      return updatedTrip;
    }
    throw Exception('Trip with ID $tripId not found');
  }

  // In-memory mock list of quotes
  static final List<Quote> _mockQuotes = [
    const Quote(
      id: 'QT-2026-0012',
      quoteId: 'QT-2026-0012',
      price: '€5,200',
      route: 'To Koper — Germany',
      vehicleType: 'Van',
      date: '24 Jun 2026',
      status: 'Accepted',
      pickupLocation: 'Germany Warehouse',
      dropLocation: 'To Koper Warehouse',
      mobileNumber: '+91 9876543210',
      address: '15 Liberation Board',
      city: 'Munich',
      country: 'Germany',
      postalCode: '80331',
      packagingType: 'Pallets',
      weight: '500 KG',
    ),
    const Quote(
      id: 'QT-2026-0013',
      quoteId: 'QT-2026-0013',
      price: '€3,150',
      route: 'Berlin — Warsaw',
      vehicleType: '14 Ft Truck',
      date: '25 Jun 2026',
      status: 'Pending',
      pickupLocation: 'Berlin Terminal',
      dropLocation: 'Warsaw Depot',
      mobileNumber: '+91 9876543210',
      address: 'Kaiser Strasse 10',
      city: 'Berlin',
      country: 'Germany',
      postalCode: '10115',
      packagingType: 'Boxes',
      weight: '1200 KG',
    ),
    const Quote(
      id: 'QT-2026-0014',
      quoteId: 'QT-2026-0014',
      price: '€7,800',
      route: 'Paris — Madrid',
      vehicleType: '20 Ft Container',
      date: '26 Jun 2026',
      status: 'Pending',
      pickupLocation: 'Paris Nord',
      dropLocation: 'Madrid Sur',
      mobileNumber: '+91 9876543210',
      address: 'Rue de Rivoli 45',
      city: 'Paris',
      country: 'France',
      postalCode: '75001',
      packagingType: 'Container',
      weight: '5000 KG',
    ),
  ];

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

    // 2. Find and update local mock list so the UI updates
    final index = _mockQuotes.indexWhere((q) => q.quoteId == quoteId);
    if (index != -1) {
      final updatedQuote = _mockQuotes[index].copyWith(status: 'Accepted');
      _mockQuotes[index] = updatedQuote;
      
      // Also automatically create an associated active trip for the driver when a quote is accepted!
      final newTripId = 'BK-2026-100${25 + index}';
      final newTrip = Trip(
        id: newTripId,
        bookingId: newTripId,
        status: 'Assigned',
        isNew: true,
        customerName: 'Rahul Sharma',
        customerPhone: updatedQuote.mobileNumber,
        cargoType: updatedQuote.packagingType,
        weight: updatedQuote.weight,
        truckInfo: 'MH01AB1234 - ${updatedQuote.vehicleType}',
        truckType: updatedQuote.vehicleType,
        pickupLocation: updatedQuote.pickupLocation,
        pickupAddress: updatedQuote.address,
        pickupDate: '${updatedQuote.date}, 10:00 AM',
        dropLocation: updatedQuote.dropLocation,
        dropAddress: '${updatedQuote.city}, ${updatedQuote.country}',
        dropEta: '28 Jun 2026, 06:00 PM',
        distanceRemainingKm: 1200.0,
        etaHours: 18.0,
        currentLocation: updatedQuote.pickupLocation,
        arrivalRequirementText: 'Shipment scheduled for delivery',
        routePoints: [updatedQuote.pickupLocation, updatedQuote.dropLocation],
      );
      
      _mockTrips.insert(0, newTrip);
      
      return updatedQuote;
    }
    
    // If not in cache (e.g. freshly created direct quote), return a default quote
    return Quote(
      id: quoteId,
      quoteId: quoteId,
      status: 'Accepted',
      date: 'Today',
      vehicleType: '20',
      packagingType: 'Palletized',
      weight: '25000 KG',
      country: 'Germany',
      city: 'Berlin',
      pickupLocation: 'Koper',
      dropLocation: 'Germany',
      price: '4500 EUR',
      route: 'Koper ➔ Germany',
      address: '',
      mobileNumber: '',
      postalCode: '',
    );
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
