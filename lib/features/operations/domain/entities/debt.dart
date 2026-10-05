import '../../../accounts/domain/entities/money.dart';

class Debt {
  const Debt({
    required this.providerId,
    required this.providerName,
    required this.accountReference,
    required this.debtReference,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  final String providerId;
  final String providerName;
  final String accountReference;
  final String? debtReference;
  final Money amount;
  final DateTime? dueDate;
  final String status;

  factory Debt.fromMap(Map<String, dynamic> map) {
    if (map['providerId'] is! String ||
        map['providerName'] is! String ||
        map['accountReference'] is! String ||
        map['amount'] is! Map ||
        map['status'] is! String) {
      throw const FormatException('Invalid debt.');
    }
    final dueDate = map['dueDate'] as String?;
    return Debt(
      providerId: map['providerId'] as String,
      providerName: map['providerName'] as String,
      accountReference: map['accountReference'] as String,
      debtReference: map['debtReference'] as String?,
      amount: Money.fromMap(Map<String, dynamic>.from(map['amount'] as Map)),
      dueDate: dueDate == null ? null : DateTime.parse(dueDate),
      status: map['status'] as String,
    );
  }
}
