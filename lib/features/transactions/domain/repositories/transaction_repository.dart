import '../entities/transaction.dart';

class TransactionsPage {
  const TransactionsPage({
    required this.items,
    required this.nextCursor,
    required this.fetchedAt,
    required this.isStale,
  });

  final List<Transaction> items;
  final String? nextCursor;
  final DateTime fetchedAt;
  final bool isStale;
}

class TransactionSnapshot {
  const TransactionSnapshot({
    required this.transaction,
    required this.fetchedAt,
    required this.isStale,
  });

  final Transaction transaction;
  final DateTime fetchedAt;
  final bool isStale;
}

abstract interface class TransactionRepository {
  Future<TransactionsPage> listTransactions(
    String accountId, {
    String? cursor,
    String? category,
    String? from,
    String? to,
  });

  Future<TransactionSnapshot> getTransaction(String id);
}
