import '../entities/trip.dart';
import '../repositories/trips_repository.dart';

class UpdateTripStatusParams {
  final String tripId;
  final String status;

  UpdateTripStatusParams({required this.tripId, required this.status});
}

class UpdateTripStatusUseCase {
  final TripsRepository repository;

  UpdateTripStatusUseCase(this.repository);

  Future<Trip> call(UpdateTripStatusParams params) {
    return repository.updateTripStatus(
      tripId: params.tripId,
      status: params.status,
    );
  }
}
