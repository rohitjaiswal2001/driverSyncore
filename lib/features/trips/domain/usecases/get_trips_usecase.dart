import '../entities/trip.dart';
import '../repositories/trips_repository.dart';

class GetTripsUseCase {
  final TripsRepository repository;

  GetTripsUseCase(this.repository);

  Future<List<Trip>> call({required String role}) {
    return repository.getTrips(role: role);
  }
}
