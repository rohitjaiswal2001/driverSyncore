import '../entities/quote.dart';
import '../repositories/trips_repository.dart';

class AcceptQuoteUseCase {
  final TripsRepository repository;

  const AcceptQuoteUseCase(this.repository);

  Future<Quote> call(String quoteId) async {
    return await repository.acceptQuote(quoteId);
  }
}
