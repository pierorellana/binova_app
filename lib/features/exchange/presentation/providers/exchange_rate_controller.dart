import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/exchange_rate.dart';
import '../../domain/repositories/exchange_rate_repository.dart';

enum ExchangeRateStatus { idle, loading, loaded, failure }

class ExchangeRateController extends ChangeNotifier {
  ExchangeRateController(this._repository);

  final ExchangeRateRepository _repository;

  ExchangeRateStatus status = ExchangeRateStatus.idle;
  ExchangeRate? rate;
  String? errorMessage;

  Future<void> load({required String base, required String quote}) async {
    status = ExchangeRateStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.getRate(base: base, quote: quote);
      rate = snapshot.rate;
      status = ExchangeRateStatus.loaded;
    } on AppFailure catch (error) {
      status = ExchangeRateStatus.failure;
      errorMessage = error.message;
    } on Object {
      status = ExchangeRateStatus.failure;
      errorMessage = 'No pudimos consultar el tipo de cambio.';
    }
    notifyListeners();
  }
}
