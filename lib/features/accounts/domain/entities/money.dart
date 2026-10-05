class Money {
  const Money({required this.amount, required this.currency});

  final String amount;
  final String currency;

  factory Money.fromMap(Map<String, dynamic> map) {
    final amount = map['amount'];
    final currency = map['currency'];
    if (amount is! String || currency is! String) {
      throw const FormatException('Invalid money value.');
    }
    return Money(amount: amount, currency: currency);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'amount': amount,
        'currency': currency,
      };
}
