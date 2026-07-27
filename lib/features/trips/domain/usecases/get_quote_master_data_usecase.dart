import '../../data/models/booking_models.dart';
import '../repositories/trips_repository.dart';

class GetQuoteMasterDataUseCase {
  final TripsRepository repository;

  const GetQuoteMasterDataUseCase(this.repository);

  Future<QuoteMasterData> call() async {
    return await repository.getQuoteMasterData();
  }
}
