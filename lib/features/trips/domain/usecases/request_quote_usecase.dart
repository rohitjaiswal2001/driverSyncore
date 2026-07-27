import '../entities/quote.dart';
import '../repositories/trips_repository.dart';

class RequestQuoteUseCase {
  final TripsRepository repository;

  const RequestQuoteUseCase(this.repository);

  Future<Quote> call(Quote quote) async {
    return await repository.requestQuote(quote);
  }
}
