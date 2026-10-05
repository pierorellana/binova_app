import 'package:binova_app/core/network/api_client.dart';
import 'package:binova_app/core/network/authenticated_api_client.dart';

import '../../../accounts/domain/entities/money.dart';
import '../../domain/entities/card.dart';

abstract interface class CardRemoteDataSource {
  Future<List<Card>> fetchCards();
  Future<Card> fetchCard(String id);
  Future<FinancialOperation> createVirtualCard({String? fundingAccountId});
  Future<FinancialOperation> fetchOperation(String id);
  Future<Card> freezeCard(String id);
  Future<Card> unfreezeCard(String id);
  Future<CardLimits> fetchLimits(String id);
  Future<CardLimits> updateLimits(String id,
      {Money? purchase, Money? withdrawal});
  Future<WalletProvisioning> provisionWallet(String id);
}

class HttpCardRemoteDataSource implements CardRemoteDataSource {
  HttpCardRemoteDataSource(this._client);

  final AuthenticatedApiClient _client;

  @override
  Future<List<Card>> fetchCards() async {
    final response = await _client.get('/cards');
    final raw = response.data;
    if (raw is! List) throw const FormatException('Invalid cards payload.');
    return raw
        .whereType<Map>()
        .map((item) => Card.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<Card> fetchCard(String id) async =>
      _cardFromResponse(await _client.get('/cards/$id'));

  @override
  Future<FinancialOperation> createVirtualCard(
      {String? fundingAccountId}) async {
    final response = await _client.post(
      '/cards/virtual',
      body: fundingAccountId == null
          ? null
          : <String, dynamic>{'fundingAccountId': fundingAccountId},
      idempotencyKey: _idempotencyKey(),
    );
    return _operationFromResponse(response);
  }

  @override
  Future<FinancialOperation> fetchOperation(String id) async {
    final response = await _client.get('/operations/$id');
    return _operationFromResponse(response);
  }

  @override
  Future<Card> freezeCard(String id) async =>
      _cardFromResponse(await _client.post('/cards/$id/freeze'));

  @override
  Future<Card> unfreezeCard(String id) async =>
      _cardFromResponse(await _client.post('/cards/$id/unfreeze'));

  @override
  Future<CardLimits> fetchLimits(String id) async {
    final response = await _client.get('/cards/$id/limits');
    if (response.data is! Map) {
      throw const FormatException('Invalid card limits payload.');
    }
    return CardLimits.fromMap(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<CardLimits> updateLimits(String id,
      {Money? purchase, Money? withdrawal}) async {
    final response = await _client.patch(
      '/cards/$id/limits',
      body: <String, dynamic>{
        if (purchase != null) 'dailyPurchaseLimit': purchase.toMap(),
        if (withdrawal != null) 'dailyWithdrawalLimit': withdrawal.toMap(),
      },
    );
    if (response.data is! Map) {
      throw const FormatException('Invalid card limits payload.');
    }
    return CardLimits.fromMap(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<WalletProvisioning> provisionWallet(String id) async {
    final response = await _client.post(
      '/cards/$id/wallet-provisioning',
      body: const <String, dynamic>{'wallet': 'apple_wallet'},
      idempotencyKey: _idempotencyKey(),
    );
    if (response.data is! Map) {
      throw const FormatException('Invalid wallet payload.');
    }
    return WalletProvisioning.fromMap(
        Map<String, dynamic>.from(response.data as Map));
  }

  Card _cardFromResponse(ApiResponse response) {
    if (response.data is! Map) {
      throw const FormatException('Invalid card payload.');
    }
    return Card.fromMap(Map<String, dynamic>.from(response.data as Map));
  }

  FinancialOperation _operationFromResponse(ApiResponse response) {
    if (response.data is! Map) {
      throw const FormatException('Invalid operation payload.');
    }
    return FinancialOperation.fromMap(
        Map<String, dynamic>.from(response.data as Map));
  }

  String _idempotencyKey() => 'binova-${DateTime.now().microsecondsSinceEpoch}';
}
