import 'package:flutter/foundation.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

enum TransactionsStatus { idle, loading, loaded, offlineStale, error }

class TransactionsController extends ChangeNotifier {
  TransactionsController(this._repository, this.accountId);

  final TransactionRepository _repository;
  final String accountId;

  TransactionsStatus status = TransactionsStatus.idle;
  List<Transaction> items = const <Transaction>[];
  String? nextCursor;
  DateTime? fetchedAt;
  String? errorMessage;
  bool isLoadingMore = false;
  String? loadMoreError;

  Future<void> load() async {
    status = TransactionsStatus.loading;
    errorMessage = null;
    loadMoreError = null;
    notifyListeners();
    try {
      final page = await _repository.listTransactions(accountId);
      items = _unique(page.items);
      nextCursor = page.nextCursor;
      fetchedAt = page.fetchedAt;
      status = page.isStale
          ? TransactionsStatus.offlineStale
          : TransactionsStatus.loaded;
    } on Object {
      status = TransactionsStatus.error;
      errorMessage = 'No pudimos cargar tus movimientos.';
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || nextCursor == null) return;
    isLoadingMore = true;
    loadMoreError = null;
    notifyListeners();
    try {
      final page = await _repository.listTransactions(
        accountId,
        cursor: nextCursor,
      );
      items = _unique(<Transaction>[...items, ...page.items]);
      nextCursor = page.nextCursor;
    } on Object {
      loadMoreError = 'No pudimos cargar más movimientos.';
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  List<Transaction> _unique(Iterable<Transaction> values) {
    final seen = <String>{};
    return values.where((item) => seen.add(item.id)).toList(growable: false);
  }
}

enum TransactionDetailStatus { idle, loading, loaded, offlineStale, error }

class TransactionDetailController extends ChangeNotifier {
  TransactionDetailController(this._repository, this.transactionId);

  final TransactionRepository _repository;
  final String transactionId;

  TransactionDetailStatus status = TransactionDetailStatus.idle;
  Transaction? transaction;
  DateTime? fetchedAt;
  String? errorMessage;

  Future<void> load() async {
    status = TransactionDetailStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.getTransaction(transactionId);
      transaction = snapshot.transaction;
      fetchedAt = snapshot.fetchedAt;
      status = snapshot.isStale
          ? TransactionDetailStatus.offlineStale
          : TransactionDetailStatus.loaded;
    } on Object {
      status = TransactionDetailStatus.error;
      errorMessage = 'No pudimos cargar el detalle del movimiento.';
    }
    notifyListeners();
  }
}
