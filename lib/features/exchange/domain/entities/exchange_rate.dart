class ExchangeRate {
  const ExchangeRate({
    required this.base,
    required this.quote,
    required this.rate,
    required this.asOf,
    required this.source,
    required this.stale,
  });

  final String base;
  final String quote;
  final String rate;
  final DateTime asOf;
  final String source;
  final bool stale;

  factory ExchangeRate.fromMap(Map<String, dynamic> map) {
    if (map['base'] is! String ||
        map['quote'] is! String ||
        map['rate'] is! String ||
        map['asOf'] is! String ||
        map['source'] is! String ||
        map['stale'] is! bool) {
      throw const FormatException('Invalid exchange rate.');
    }
    return ExchangeRate(
      base: map['base'] as String,
      quote: map['quote'] as String,
      rate: map['rate'] as String,
      asOf: DateTime.parse(map['asOf'] as String),
      source: map['source'] as String,
      stale: map['stale'] as bool,
    );
  }

  ExchangeRate copyWith({bool? stale}) => ExchangeRate(
        base: base,
        quote: quote,
        rate: rate,
        asOf: asOf,
        source: source,
        stale: stale ?? this.stale,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'base': base,
        'quote': quote,
        'rate': rate,
        'asOf': asOf.toIso8601String(),
        'source': source,
        'stale': stale,
      };
}
