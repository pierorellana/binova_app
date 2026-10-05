import 'package:flutter/foundation.dart';

import '../../../accounts/domain/entities/money.dart';
import '../../../../core/security/biometric_authenticator.dart';
import '../../domain/entities/card.dart';
import '../../domain/repositories/card_repository.dart';

enum CardsStatus { idle, loading, loaded, offlineStale, error }

class CardsController extends ChangeNotifier {
  CardsController(this._repository);

  final CardRepository _repository;

  CardsStatus status = CardsStatus.idle;
  List<Card> cards = const <Card>[];
  DateTime? fetchedAt;
  String? errorMessage;

  Future<void> load() async {
    status = CardsStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.listCards();
      cards = snapshot.cards;
      fetchedAt = snapshot.fetchedAt;
      status = snapshot.isStale ? CardsStatus.offlineStale : CardsStatus.loaded;
    } on Object {
      status = CardsStatus.error;
      errorMessage = 'No pudimos cargar tus tarjetas.';
    }
    notifyListeners();
  }
}

enum CardDetailStatus { idle, loading, loaded, offlineStale, error }

class CardDetailController extends ChangeNotifier {
  CardDetailController(this._repository, this.cardId);

  final CardRepository _repository;
  final String cardId;

  CardDetailStatus status = CardDetailStatus.idle;
  Card? card;
  CardLimits? limits;
  DateTime? fetchedAt;
  String? errorMessage;
  bool isUpdatingState = false;
  bool isLoadingLimits = false;
  bool isUpdatingLimits = false;
  bool isProvisioningWallet = false;
  String? actionError;
  WalletProvisioning? walletProvisioning;

  Future<void> load() async {
    status = CardDetailStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.getCard(cardId);
      card = snapshot.card;
      fetchedAt = snapshot.fetchedAt;
      status = snapshot.isStale ? CardDetailStatus.offlineStale : CardDetailStatus.loaded;
    } on Object {
      status = CardDetailStatus.error;
      errorMessage = 'No pudimos cargar el detalle de la tarjeta.';
    }
    notifyListeners();
  }

  Future<void> toggleFreeze() async {
    final current = card;
    if (current == null || isUpdatingState) return;
    isUpdatingState = true;
    actionError = null;
    notifyListeners();
    try {
      card = current.status == CardStatus.frozen
          ? await _repository.unfreezeCard(current.id)
          : await _repository.freezeCard(current.id);
    } on Object {
      actionError = 'No pudimos actualizar el estado de la tarjeta.';
    } finally {
      isUpdatingState = false;
      notifyListeners();
    }
  }

  Future<void> loadLimits() async {
    if (isLoadingLimits) return;
    isLoadingLimits = true;
    actionError = null;
    notifyListeners();
    try {
      limits = await _repository.getLimits(cardId);
    } on Object {
      actionError = 'No pudimos cargar los límites.';
    } finally {
      isLoadingLimits = false;
      notifyListeners();
    }
  }

  Future<void> updateLimits({required String purchase, required String withdrawal}) async {
    if (isUpdatingLimits || limits == null) return;
    isUpdatingLimits = true;
    actionError = null;
    notifyListeners();
    try {
      limits = await _repository.updateLimits(
        cardId,
        purchase: MoneyValue.parse(purchase, limits!.dailyPurchaseLimit.currency),
        withdrawal: MoneyValue.parse(withdrawal, limits!.dailyWithdrawalLimit.currency),
      );
    } on Object {
      actionError = 'No pudimos actualizar los límites.';
    } finally {
      isUpdatingLimits = false;
      notifyListeners();
    }
  }

  Future<void> provisionWallet() async {
    if (isProvisioningWallet) return;
    isProvisioningWallet = true;
    actionError = null;
    notifyListeners();
    try {
      walletProvisioning = await _repository.provisionWallet(cardId);
    } on Object {
      actionError = 'No pudimos enviar la tarjeta a Apple Wallet.';
    } finally {
      isProvisioningWallet = false;
      notifyListeners();
    }
  }
}

class MoneyValue {
  const MoneyValue._(this.amount, this.currency);

  final String amount;
  final String currency;

  static Money parse(String value, String currency) {
    if (!RegExp(r'^\d{1,16}(\.\d{1,2})?$').hasMatch(value)) {
      throw const FormatException('Invalid money amount.');
    }
    return Money(amount: value, currency: currency);
  }
}

enum CardCreationStatus { idle, authenticating, creating, pending, completed, failure }

class CardCreationController extends ChangeNotifier {
  CardCreationController(this._repository, this._biometric);

  final CardRepository _repository;
  final BiometricAuthenticator _biometric;

  CardCreationStatus status = CardCreationStatus.idle;
  FinancialOperation? operation;
  Card? card;
  String? errorMessage;

  Future<void> start({String? fundingAccountId}) async {
    if (status == CardCreationStatus.authenticating || status == CardCreationStatus.creating) return;
    errorMessage = null;
    if (!_biometric.isAvailable) {
      status = CardCreationStatus.failure;
      errorMessage = 'Face ID no está disponible en este dispositivo.';
      notifyListeners();
      return;
    }
    status = CardCreationStatus.authenticating;
    notifyListeners();
    if (!await _biometric.authenticate()) {
      status = CardCreationStatus.failure;
      errorMessage = 'No pudimos validar tu identidad.';
      notifyListeners();
      return;
    }
    status = CardCreationStatus.creating;
    notifyListeners();
    try {
      operation = await _repository.createVirtualCard(
        fundingAccountId: fundingAccountId,
      );
      await _resolveOperation();
    } on Object {
      status = CardCreationStatus.failure;
      errorMessage = 'No pudimos solicitar tu tarjeta virtual.';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final current = operation;
    if (current == null || status == CardCreationStatus.creating) return;
    status = CardCreationStatus.creating;
    errorMessage = null;
    notifyListeners();
    try {
      operation = await _repository.getOperation(current.id);
      await _resolveOperation();
    } on Object {
      status = CardCreationStatus.failure;
      errorMessage = 'No pudimos consultar el estado de la creación.';
      notifyListeners();
    }
  }

  Future<void> _resolveOperation() async {
    final current = operation!;
    if (current.status == 'succeeded' && current.resourceId != null) {
      card = (await _repository.getCard(current.resourceId!)).card;
      status = CardCreationStatus.completed;
    } else if (current.status == 'failed') {
      status = CardCreationStatus.failure;
      errorMessage = current.failureCode ?? 'La creación fue rechazada.';
    } else {
      status = CardCreationStatus.pending;
    }
    notifyListeners();
  }
}
