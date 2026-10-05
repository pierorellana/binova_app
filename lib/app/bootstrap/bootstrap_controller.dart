import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

enum BootstrapStatus { idle, loading, ready, failure }

class BootstrapController extends ChangeNotifier {
  BootstrapController(
      {required AuthRepository repository, required AppConfig config})
      : _repository = repository,
        _config = config;

  final AuthRepository _repository;
  final AppConfig _config;

  BootstrapStatus status = BootstrapStatus.idle;
  InitialDestination? destination;
  String? errorMessage;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    status = BootstrapStatus.loading;
    notifyListeners();
    final stopwatch = Stopwatch()..start();
    try {
      final resolved = await _repository.resolveInitialDestination();
      final remaining = _config.splashMinimumDuration - stopwatch.elapsed;
      if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      destination = resolved;
      status = BootstrapStatus.ready;
    } on Object {

      _started = false;
      status = BootstrapStatus.failure;
      errorMessage = 'No pudimos preparar la aplicación.';
    }
    notifyListeners();
  }
}
