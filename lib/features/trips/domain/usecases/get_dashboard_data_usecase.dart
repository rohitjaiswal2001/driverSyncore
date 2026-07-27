import '../entities/dashboard_data.dart';
import '../repositories/trips_repository.dart';

class GetDashboardDataUseCase {
  final TripsRepository repository;

  GetDashboardDataUseCase(this.repository);

  Future<DashboardData> call() {
    return repository.getDashboardData();
  }
}
