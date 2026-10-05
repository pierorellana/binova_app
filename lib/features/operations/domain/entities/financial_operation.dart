import '../../../accounts/domain/entities/money.dart';

class FinancialOperation {
  const FinancialOperation({
    required this.id,
    required this.operationType,
    required this.status,
    required this.amount,
    required this.resourceId,
    required this.providerReference,
    required this.failureCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String operationType;
  final String status;
  final Money? amount;
  final String? resourceId;
  final String? providerReference;
  final String? failureCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FinancialOperation.fromMap(Map<String, dynamic> map) {
    if (map['id'] is! String ||
        map['operationType'] is! String ||
        map['status'] is! String ||
        map['createdAt'] is! String ||
        map['updatedAt'] is! String) {
      throw const FormatException('Invalid financial operation.');
    }
    final rawAmount = map['amount'];
    return FinancialOperation(
      id: map['id'] as String,
      operationType: map['operationType'] as String,
      status: map['status'] as String,
      amount: rawAmount is Map
          ? Money.fromMap(Map<String, dynamic>.from(rawAmount))
          : null,
      resourceId: map['resourceId'] as String?,
      providerReference: map['providerReference'] as String?,
      failureCode: map['failureCode'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  bool get isPending => status == 'processing' || status == 'pending';
  bool get isSucceeded => status == 'succeeded';
  bool get isFailed => status == 'failed';
}
