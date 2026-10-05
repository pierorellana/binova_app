import '../../../accounts/domain/entities/money.dart';

enum TransactionKind { income, expense }

enum TransactionStatus { processing, pending, succeeded, failed }

class Transaction {
  const Transaction({
    required this.id,
    required this.kind,
    required this.merchant,
    required this.description,
    required this.category,
    required this.amount,
    required this.status,
    required this.occurredAt,
    required this.reference,
  });

  final String id;
  final TransactionKind kind;
  final String? merchant;
  final String description;
  final String category;
  final Money amount;
  final TransactionStatus status;
  final DateTime occurredAt;
  final String reference;

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final rawKind = map['kind'];
    final rawAmount = map['amount'];
    final rawStatus = map['status'];
    final rawDate = map['occurredAt'];
    if (map['id'] is! String ||
        rawKind is! String ||
        map['description'] is! String ||
        map['category'] is! String ||
        rawAmount is! Map ||
        rawStatus is! String ||
        rawDate is! String ||
        map['reference'] is! String) {
      throw const FormatException('Invalid transaction.');
    }
    return Transaction(
      id: map['id'] as String,
      kind: _kind(rawKind),
      merchant: map['merchant'] as String?,
      description: map['description'] as String,
      category: map['category'] as String,
      amount: Money.fromMap(Map<String, dynamic>.from(rawAmount)),
      status: _status(rawStatus),
      occurredAt: DateTime.parse(rawDate),
      reference: map['reference'] as String,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'merchant': merchant,
        'description': description,
        'category': category,
        'amount': amount.toMap(),
        'status': status.name,
        'occurredAt': occurredAt.toIso8601String(),
        'reference': reference,
      };

  static TransactionKind _kind(String value) => switch (value) {
        'income' => TransactionKind.income,
        'expense' => TransactionKind.expense,
        _ => throw const FormatException('Invalid transaction kind.'),
      };

  static TransactionStatus _status(String value) => switch (value) {
        'processing' => TransactionStatus.processing,
        'pending' => TransactionStatus.pending,
        'succeeded' => TransactionStatus.succeeded,
        'failed' => TransactionStatus.failed,
        _ => throw const FormatException('Invalid transaction status.'),
      };
}
