import '../entities/quote.dart';
import '../repositories/trips_repository.dart';

class CreateBookingQuoteUseCase {
  final TripsRepository repository;

  const CreateBookingQuoteUseCase(this.repository);

  Future<Quote> call({
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
    return await repository.createBookingQuote(
      direction: direction,
      containerTypeId: containerTypeId,
      packagingId: packagingId,
      weightOfGoods: weightOfGoods,
      countryId: countryId,
      postalCode: postalCode,
      city: city,
      pickupDate: pickupDate,
      distanceKm: distanceKm,
      address: address,
      mobileNumber: mobileNumber,
    );
  }
}
