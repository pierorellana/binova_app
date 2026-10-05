import '../../../../core/storage/json_cache_store.dart';
import '../../../accounts/domain/entities/money.dart';
import '../../domain/entities/card.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/card_remote_data_source.dart';

class CardRepositoryImpl implements CardRepository {
  CardRepositoryImpl(
      {required CardRemoteDataSource remote, required JsonCacheStore cache})
      : _remote = remote,
        _cache = cache;

  final CardRemoteDataSource _remote;
  final JsonCacheStore _cache;

  @override
  Future<CardsSnapshot> listCards() async {
    try {
      final cards = await _remote.fetchCards();
      await _cache.write(
          'binova.cache.cards.v1', cards.map((card) => card.toMap()).toList());
      return CardsSnapshot(
          cards: cards, fetchedAt: DateTime.now(), isStale: false);
    } on Object {
      final cached = await _cache.read('binova.cache.cards.v1');
      if (cached == null || cached.payload is! List) rethrow;
      return CardsSnapshot(
        cards: (cached.payload as List)
            .whereType<Map>()
            .map((item) => Card.fromMap(Map<String, dynamic>.from(item)))
            .toList(growable: false),
        fetchedAt: cached.fetchedAt,
        isStale: true,
      );
    }
  }

  @override
  Future<CardSnapshot> getCard(String id) async {
    final key = 'binova.cache.card.v1.$id';
    try {
      final card = await _remote.fetchCard(id);
      await _cache.write(key, card.toMap());
      return CardSnapshot(
          card: card, fetchedAt: DateTime.now(), isStale: false);
    } on Object {
      final cached = await _cache.read(key);
      if (cached == null || cached.payload is! Map) rethrow;
      return CardSnapshot(
        card: Card.fromMap(Map<String, dynamic>.from(cached.payload as Map)),
        fetchedAt: cached.fetchedAt,
        isStale: true,
      );
    }
  }

  @override
  Future<FinancialOperation> createVirtualCard({String? fundingAccountId}) =>
      _remote.createVirtualCard(fundingAccountId: fundingAccountId);

  @override
  Future<FinancialOperation> getOperation(String id) =>
      _remote.fetchOperation(id);

  @override
  Future<Card> freezeCard(String id) => _remote.freezeCard(id);

  @override
  Future<Card> unfreezeCard(String id) => _remote.unfreezeCard(id);

  @override
  Future<CardLimits> getLimits(String id) => _remote.fetchLimits(id);

  @override
  Future<CardLimits> updateLimits(String id,
          {Money? purchase, Money? withdrawal}) =>
      _remote.updateLimits(id, purchase: purchase, withdrawal: withdrawal);

  @override
  Future<WalletProvisioning> provisionWallet(String id) =>
      _remote.provisionWallet(id);
}
