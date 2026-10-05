import 'package:flutter/foundation.dart';

import '../../../../core/security/biometric_authenticator.dart';
import '../../domain/entities/financial_operation.dart';
import '../../domain/repositories/operations_repository.dart';

enum OperationFlowStatus { idle, authenticating, submitting, pending, succeeded, failed }

class OperationFlowController extends ChangeNotifier {
  OperationFlowController({required OperationsRepository repository, required BiometricAuthenticator biometric})
      : _repository = repository,
        _biometric = biometric;

  final OperationsRepository _repository;
  final BiometricAuthenticator _biometric;

  OperationFlowStatus status = OperationFlowStatus.idle;
  FinancialOperation? operation;
  String? errorMessage;

  /// True when the last [submit] stopped at the biometric step (nothing was
  /// sent), so the UI can offer the Face ID fallback instead of a result.
  bool authenticationFailed = false;
  String _idempotencyKey = '';

  Future<void> submit(Future<FinancialOperation> Function(String idempotencyKey) action) async {
    if (status == OperationFlowStatus.authenticating || status == OperationFlowStatus.submitting) return;
    errorMessage = null;
    authenticationFailed = false;
    _idempotencyKey = _idempotencyKey.isEmpty ? _newKey() : _idempotencyKey;
    if (!_biometric.isAvailable) {
      status = OperationFlowStatus.failed;
      authenticationFailed = true;
      errorMessage = 'Face ID no está disponible en este dispositivo.';
      notifyListeners();
      return;
    }
    status = OperationFlowStatus.authenticating;
    notifyListeners();
    if (!await _biometric.authenticate()) {
      status = OperationFlowStatus.failed;
      authenticationFailed = true;
      errorMessage = 'No pudimos verificar tu identidad.';
      notifyListeners();
      return;
    }
    status = OperationFlowStatus.submitting;
    notifyListeners();
    try {
      operation = await action(_idempotencyKey);
      _setOperationStatus();
    } on Object {
      status = OperationFlowStatus.failed;
      errorMessage = 'No pudimos enviar la operación.';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final current = operation;
    if (current == null) return;
    status = OperationFlowStatus.submitting;
    errorMessage = null;
    notifyListeners();
    try {
      operation = await _repository.getOperation(current.id);
      _setOperationStatus();
    } on Object {
      status = OperationFlowStatus.pending;
      errorMessage = 'No pudimos consultar el estado. No repitas la operación.';
      notifyListeners();
    }
  }

  /// Starts a new, independent operation (new idempotency key).
  void reset() {
    status = OperationFlowStatus.idle;
    operation = null;
    errorMessage = null;
    authenticationFailed = false;
    _idempotencyKey = '';
    notifyListeners();
  }

  void _setOperationStatus() {
    final current = operation!;
    if (current.isSucceeded) {
      status = OperationFlowStatus.succeeded;
    } else if (current.isFailed) {
      status = OperationFlowStatus.failed;
      errorMessage = current.failureCode ?? 'La operación fue rechazada.';
    } else {
      status = OperationFlowStatus.pending;
    }
    notifyListeners();
  }

  String _newKey() => 'binova-${DateTime.now().microsecondsSinceEpoch}';
}
