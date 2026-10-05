import 'package:flutter/foundation.dart';

import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

enum AccountsStatus { idle, loading, loaded, offlineStale, error }

class AccountsController extends ChangeNotifier {
  AccountsController(this._repository);

  final AccountRepository _repository;

  AccountsStatus status = AccountsStatus.idle;
  List<Account> accounts = const <Account>[];
  DateTime? fetchedAt;
  String? errorMessage;

  Future<void> load() async {
    status = AccountsStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.listAccounts();
      accounts = snapshot.accounts;
      fetchedAt = snapshot.fetchedAt;
      status = snapshot.isStale
          ? AccountsStatus.offlineStale
          : AccountsStatus.loaded;
    } on Object {
      status = AccountsStatus.error;
      errorMessage = 'No pudimos cargar tus productos.';
    }
    notifyListeners();
  }
}

enum AccountDetailStatus { idle, loading, loaded, offlineStale, error }

class AccountDetailController extends ChangeNotifier {
  AccountDetailController(this._repository, this.accountId);

  final AccountRepository _repository;
  final String accountId;

  AccountDetailStatus status = AccountDetailStatus.idle;
  Account? account;
  DateTime? fetchedAt;
  String? errorMessage;

  Future<void> load() async {
    status = AccountDetailStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.getAccount(accountId);
      account = snapshot.account;
      fetchedAt = snapshot.fetchedAt;
      status = snapshot.isStale
          ? AccountDetailStatus.offlineStale
          : AccountDetailStatus.loaded;
    } on Object {
      status = AccountDetailStatus.error;
      errorMessage = 'No pudimos cargar el detalle de la cuenta.';
    }
    notifyListeners();
  }
}
