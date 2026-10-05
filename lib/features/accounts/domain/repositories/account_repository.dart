import '../entities/account.dart';

class AccountsSnapshot {
  const AccountsSnapshot({
    required this.accounts,
    required this.fetchedAt,
    required this.isStale,
  });

  final List<Account> accounts;
  final DateTime fetchedAt;
  final bool isStale;
}

class AccountSnapshot {
  const AccountSnapshot({
    required this.account,
    required this.fetchedAt,
    required this.isStale,
  });

  final Account account;
  final DateTime fetchedAt;
  final bool isStale;
}

abstract interface class AccountRepository {
  Future<AccountsSnapshot> listAccounts();
  Future<AccountSnapshot> getAccount(String id);
}
