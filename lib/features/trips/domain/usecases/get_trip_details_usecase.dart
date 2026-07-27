import '../entities/trip.dart';
import '../repositories/trips_repository.dart';

class GetTripDetailsUseCase {
  final TripsRepository repository;

  GetTripDetailsUseCase(this.repository);

  Future<Trip> call(String tripId) {
    return repository.getTripDetails(tripId);
  }
}
