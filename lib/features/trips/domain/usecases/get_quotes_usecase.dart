import '../entities/quote.dart';
import '../repositories/trips_repository.dart';

class GetQuotesUseCase {
  final TripsRepository repository;

  const GetQuotesUseCase(this.repository);

  Future<List<Quote>> call({String? status}) async {
    return await repository.getQuotes(status: status);
  }
}
