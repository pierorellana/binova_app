import 'money.dart';

enum AccountType { savings, current, credit }

enum AccountStatus { active, blocked, closed }

class Account {
  const Account({
    required this.id,
    required this.type,
    required this.name,
    required this.maskedNumber,
    required this.currency,
    required this.ledgerBalance,
    required this.availableBalance,
    required this.status,
    required this.lastUpdatedAt,
  });

  final String id;
  final AccountType type;
  final String name;
  final String maskedNumber;
  final String currency;
  final Money ledgerBalance;
  final Money availableBalance;
  final AccountStatus status;
  final DateTime lastUpdatedAt;

  factory Account.fromMap(Map<String, dynamic> map) {
    final rawType = map['type'];
    final rawStatus = map['status'];
    final rawLedger = map['ledgerBalance'];
    final rawAvailable = map['availableBalance'];
    final rawDate = map['lastUpdatedAt'];
    if (map['id'] is! String ||
        rawType is! String ||
        map['name'] is! String ||
        map['maskedNumber'] is! String ||
        map['currency'] is! String ||
        rawLedger is! Map ||
        rawAvailable is! Map ||
        rawStatus is! String ||
        rawDate is! String) {
      throw const FormatException('Invalid account.');
    }
    return Account(
      id: map['id'] as String,
      type: _accountType(rawType),
      name: map['name'] as String,
      maskedNumber: map['maskedNumber'] as String,
      currency: map['currency'] as String,
      ledgerBalance: Money.fromMap(Map<String, dynamic>.from(rawLedger)),
      availableBalance: Money.fromMap(Map<String, dynamic>.from(rawAvailable)),
      status: _accountStatus(rawStatus),
      lastUpdatedAt: DateTime.parse(rawDate),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'name': name,
        'maskedNumber': maskedNumber,
        'currency': currency,
        'ledgerBalance': ledgerBalance.toMap(),
        'availableBalance': availableBalance.toMap(),
        'status': status.name,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  static AccountType _accountType(String value) => switch (value) {
        'savings' => AccountType.savings,
        'current' => AccountType.current,
        'credit' => AccountType.credit,
        _ => throw const FormatException('Invalid account type.'),
      };

  static AccountStatus _accountStatus(String value) => switch (value) {
        'active' => AccountStatus.active,
        'blocked' => AccountStatus.blocked,
        'closed' => AccountStatus.closed,
        _ => throw const FormatException('Invalid account status.'),
      };
}
