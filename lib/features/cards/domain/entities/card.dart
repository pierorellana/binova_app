import '../../../accounts/domain/entities/money.dart';

enum CardType { debit, credit, virtual }

enum CardStatus { active, frozen, pending, blocked }

class Card {
  const Card({
    required this.id,
    required this.type,
    required this.productName,
    required this.maskedPan,
    required this.status,
    required this.isVirtual,
    required this.createdAt,
    required this.frozenAt,
  });

  final String id;
  final CardType type;
  final String productName;
  final String maskedPan;
  final CardStatus status;
  final bool isVirtual;
  final DateTime createdAt;
  final DateTime? frozenAt;

  factory Card.fromMap(Map<String, dynamic> map) {
    final rawType = map['type'];
    final rawStatus = map['status'];
    final rawCreatedAt = map['createdAt'];
    if (map['id'] is! String ||
        rawType is! String ||
        map['productName'] is! String ||
        map['maskedPan'] is! String ||
        rawStatus is! String ||
        map['isVirtual'] is! bool ||
        rawCreatedAt is! String) {
      throw const FormatException('Invalid card.');
    }
    return Card(
      id: map['id'] as String,
      type: _type(rawType),
      productName: map['productName'] as String,
      maskedPan: map['maskedPan'] as String,
      status: _status(rawStatus),
      isVirtual: map['isVirtual'] as bool,
      createdAt: DateTime.parse(rawCreatedAt),
      frozenAt: (map['frozenAt'] as String?) == null
          ? null
          : DateTime.parse(map['frozenAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'productName': productName,
        'maskedPan': maskedPan,
        'status': status.name,
        'isVirtual': isVirtual,
        'createdAt': createdAt.toIso8601String(),
        'frozenAt': frozenAt?.toIso8601String(),
      };

  static CardType _type(String value) => switch (value) {
        'debit' => CardType.debit,
        'credit' => CardType.credit,
        'virtual' => CardType.virtual,
        _ => throw const FormatException('Invalid card type.'),
      };

  static CardStatus _status(String value) => switch (value) {
        'active' => CardStatus.active,
        'frozen' => CardStatus.frozen,
        'pending' => CardStatus.pending,
        'blocked' => CardStatus.blocked,
        _ => throw const FormatException('Invalid card status.'),
      };
}

class FinancialOperation {
  const FinancialOperation({
    required this.id,
    required this.operationType,
    required this.status,
    required this.resourceId,
    required this.failureCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String operationType;
  final String status;
  final String? resourceId;
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
    return FinancialOperation(
      id: map['id'] as String,
      operationType: map['operationType'] as String,
      status: map['status'] as String,
      resourceId: map['resourceId'] as String?,
      failureCode: map['failureCode'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class CardLimits {
  const CardLimits({
    required this.cardId,
    required this.dailyPurchaseLimit,
    required this.dailyWithdrawalLimit,
    required this.updatedAt,
  });

  final String cardId;
  final Money dailyPurchaseLimit;
  final Money dailyWithdrawalLimit;
  final DateTime updatedAt;

  factory CardLimits.fromMap(Map<String, dynamic> map) {
    if (map['cardId'] is! String ||
        map['dailyPurchaseLimit'] is! Map ||
        map['dailyWithdrawalLimit'] is! Map ||
        map['updatedAt'] is! String) {
      throw const FormatException('Invalid card limits.');
    }
    return CardLimits(
      cardId: map['cardId'] as String,
      dailyPurchaseLimit: Money.fromMap(
        Map<String, dynamic>.from(map['dailyPurchaseLimit'] as Map),
      ),
      dailyWithdrawalLimit: Money.fromMap(
        Map<String, dynamic>.from(map['dailyWithdrawalLimit'] as Map),
      ),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class WalletProvisioning {
  const WalletProvisioning({
    required this.id,
    required this.cardId,
    required this.status,
    required this.provisioningUrl,
    required this.createdAt,
  });

  final String id;
  final String cardId;
  final String status;
  final String? provisioningUrl;
  final DateTime createdAt;

  factory WalletProvisioning.fromMap(Map<String, dynamic> map) {
    if (map['id'] is! String ||
        map['cardId'] is! String ||
        map['status'] is! String ||
        map['createdAt'] is! String) {
      throw const FormatException('Invalid wallet provisioning.');
    }
    return WalletProvisioning(
      id: map['id'] as String,
      cardId: map['cardId'] as String,
      status: map['status'] as String,
      provisioningUrl: map['provisioningUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
