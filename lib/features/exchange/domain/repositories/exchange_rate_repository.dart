import '../entities/exchange_rate.dart';

class ExchangeRateSnapshot {
  const ExchangeRateSnapshot({
    required this.rate,
    required this.fetchedAt,
    required this.isStale,
  });

  final ExchangeRate rate;
  final DateTime fetchedAt;
  final bool isStale;
}

abstract interface class ExchangeRateRepository {
  Future<ExchangeRateSnapshot> getRate({
    required String base,
    required String quote,
  });
}
