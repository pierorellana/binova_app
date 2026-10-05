import 'package:flutter/foundation.dart';

enum AppEvent {
  screenView,
  loginSuccess,
  loginFailure,
  logout,
  offlineShown,
  retryTriggered,
  cacheFallbackUsed,
  operationStarted,
  operationResult,
}

abstract interface class Observability {
  void track(AppEvent event, {Map<String, Object?> parameters = const {}});
}

class NoopObservability implements Observability {
  const NoopObservability();

  @override
  void track(AppEvent event, {Map<String, Object?> parameters = const {}}) {}
}

class DebugObservability implements Observability {
  const DebugObservability();

  @override
  void track(AppEvent event, {Map<String, Object?> parameters = const {}}) {
    if (!kDebugMode) return;
    debugPrint('BInova event=${event.name} params=${_safe(parameters)}');
  }

  Map<String, Object?> _safe(Map<String, Object?> parameters) {
    const allowed = <String>{'code', 'status', 'screen', 'operationType'};
    return Map<String, Object?>.fromEntries(
      parameters.entries.where((entry) => allowed.contains(entry.key)),
    );
  }
}
