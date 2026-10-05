import 'package:flutter/foundation.dart';

import '../../domain/entities/dashboard_config.dart';
import '../../domain/repositories/dashboard_repository.dart';

enum DashboardStatus { idle, loading, loaded, offlineStale, error }

class DashboardController extends ChangeNotifier {
  DashboardController(this._repository);

  final DashboardRepository _repository;

  DashboardStatus status = DashboardStatus.idle;
  DashboardConfig? config;
  DateTime? fetchedAt;
  String? errorMessage;

  Future<void> load() async {
    status = DashboardStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.getDashboard();
      config = snapshot.config;
      fetchedAt = snapshot.fetchedAt;
      status = snapshot.isStale
          ? DashboardStatus.offlineStale
          : DashboardStatus.loaded;
    } on Object {
      status = DashboardStatus.error;
      errorMessage = 'No pudimos cargar tu inicio.';
    }
    notifyListeners();
  }
}
