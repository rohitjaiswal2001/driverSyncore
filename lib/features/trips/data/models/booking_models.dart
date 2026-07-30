import '../../domain/entities/quote.dart';

class Country {
  final int id;
  final String name;
  final String code;

  const Country({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}

class ContainerType {
  final int id;
  final String name;

  const ContainerType({
    required this.id,
    required this.name,
  });

  factory ContainerType.fromJson(Map<String, dynamic> json) {
    return ContainerType(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

class Packaging {
  final int id;
  final String name;

  const Packaging({
    required this.id,
    required this.name,
  });

  factory Packaging.fromJson(Map<String, dynamic> json) {
    return Packaging(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

class QuoteMasterData {
  final List<Country> countries;
  final List<ContainerType> containers;
  final List<Packaging> packagings;

  const QuoteMasterData({
    required this.countries,
    required this.containers,
    required this.packagings,
  });

  factory QuoteMasterData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    final rawCountries = data['countries'] as List? ?? [];
    final rawContainers = data['containers'] as List? ?? [];
    final rawPackagings = data['packagings'] as List? ?? [];

    return QuoteMasterData(
      countries: rawCountries.map((c) => Country.fromJson(c as Map<String, dynamic>)).toList(),
      containers: rawContainers.map((c) => ContainerType.fromJson(c as Map<String, dynamic>)).toList(),
      packagings: rawPackagings.map((p) => Packaging.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

Quote mapBookingQuoteResponseToQuote(Map<String, dynamic> json, String address, String mobileNumber) {
  final data = json['data'] as Map<String, dynamic>;
  final id = data['id'].toString();
  // Matches how the admin panel labels bookings (e.g. "#29").
  final quoteId = '#${data['id']}';
  
  // Check if weight class is ON_REQUEST or auto_pricing is "0"
  final weightClass = data['weight_class'] as Map<String, dynamic>?;
  final isOnRequest = weightClass != null && 
      (weightClass['class']?.toString().toUpperCase() == 'ON_REQUEST' ||
       weightClass['auto_pricing']?.toString() == '0' ||
       weightClass['auto_pricing'] == 0);
  
  final price = isOnRequest ? 'On Request' : '€${data['raw_price'] ?? 0}';
  final route = '${data['pickup_location'] ?? ''} ➔ ${data['drop_location'] ?? ''}';
  
  final containerName = (data['container_type'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
  final packagingName = (data['packaging'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
  final countryName = (data['country'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
  final bidStatusCode = (data['bid_status'] as Map<String, dynamic>?)?['code']?.toString();
  
  final rawDistance = data['distance_km'];
  final distanceKm = rawDistance != null ? (double.tryParse(rawDistance.toString())?.toInt() ?? 0) : 0;

  return Quote(
    id: id,
    quoteId: quoteId,
    price: price,
    route: route,
    vehicleType: containerName,
    date: data['pickup_date'] as String? ?? '',
    status: bidStatusCode ?? (isOnRequest ? 'ON_REQUEST' : 'CALCULATED'),
    pickupLocation: data['pickup_location'] as String? ?? '',
    dropLocation: data['drop_location'] as String? ?? '',
    mobileNumber: mobileNumber,
    address: address,
    city: data['city'] as String? ?? '',
    country: countryName,
    postalCode: data['postal_code'] as String? ?? '',
    packagingType: packagingName,
    weight: '${data['weight_of_goods']} KG',
    distanceKm: distanceKm,
    transitTime: data['transit_time'] as String? ?? '',
  );
}

Quote mapBookingItemToQuote(Map<String, dynamic> data) {
  final id = data['id']?.toString() ?? '';
  final quoteId = '#$id';
  
  final rawPrice = data['raw_price'];
  final priceVal = rawPrice != null ? double.tryParse(rawPrice.toString()) : null;
  final price = priceVal != null && priceVal > 0 ? '€${priceVal.toStringAsFixed(2)}' : 'On Request';
  
  final pickup = data['pickup_location']?.toString() ?? '';
  final drop = data['drop_location']?.toString() ?? '';
  final route = '$pickup ➔ $drop';
  
  final bidStatus = data['bid_status'] as Map<String, dynamic>?;
  final statusLabel = bidStatus != null ? (bidStatus['code']?.toString() ?? '') : '';
  
  final rawDistance = data['distance_km'];
  final distanceKm = rawDistance != null ? (double.tryParse(rawDistance.toString())?.toInt() ?? 0) : 0;
  
  final containerName = (data['container_type'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
  final packagingName = (data['packaging'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
  final countryName = (data['country'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
  
  String dateStr = '2026-07-14';
  if (data['pickup_date'] != null) {
    dateStr = data['pickup_date'].toString();
  } else if (data['created_at'] != null) {
    dateStr = data['created_at'].toString().split('T').first;
  }

  return Quote(
    id: id,
    quoteId: quoteId,
    price: price,
    route: route,
    vehicleType: containerName,
    date: dateStr,
    status: statusLabel.isNotEmpty ? statusLabel : 'ON_REQUEST',
    pickupLocation: pickup,
    dropLocation: drop,
    mobileNumber: data['mobile_number']?.toString() ?? '',
    address: data['address']?.toString() ?? '',
    city: data['city']?.toString() ?? '',
    country: countryName,
    postalCode: data['postal_code']?.toString() ?? '',
    packagingType: packagingName,
    weight: data['weight_of_goods'] != null ? '${data['weight_of_goods']} KG' : '500 KG',
    distanceKm: distanceKm,
    transitTime: data['transit_time']?.toString() ?? '',
  );
}
