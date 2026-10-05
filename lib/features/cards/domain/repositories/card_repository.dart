import '../entities/card.dart';
import '../../../accounts/domain/entities/money.dart';

class CardsSnapshot {
  const CardsSnapshot({
    required this.cards,
    required this.fetchedAt,
    required this.isStale,
  });

  final List<Card> cards;
  final DateTime fetchedAt;
  final bool isStale;
}

class CardSnapshot {
  const CardSnapshot({
    required this.card,
    required this.fetchedAt,
    required this.isStale,
  });

  final Card card;
  final DateTime fetchedAt;
  final bool isStale;
}

abstract interface class CardRepository {
  Future<CardsSnapshot> listCards();
  Future<CardSnapshot> getCard(String id);
  Future<FinancialOperation> createVirtualCard({String? fundingAccountId});
  Future<FinancialOperation> getOperation(String id);
  Future<Card> freezeCard(String id);
  Future<Card> unfreezeCard(String id);
  Future<CardLimits> getLimits(String id);
  Future<CardLimits> updateLimits(String id,
      {Money? purchase, Money? withdrawal});
  Future<WalletProvisioning> provisionWallet(String id);
}
