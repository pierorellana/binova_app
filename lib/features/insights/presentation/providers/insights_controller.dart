import 'package:flutter/foundation.dart';

import '../../domain/entities/insights.dart';
import '../../domain/repositories/insights_repository.dart';

enum InsightsStatus { idle, loading, loaded, offlineStale, empty, error }

class InsightsController extends ChangeNotifier {
  InsightsController(this._repository);

  final InsightsRepository _repository;

  InsightsStatus status = InsightsStatus.idle;
  Insights? insights;
  DateTime? fetchedAt;
  String? errorMessage;

  Future<void> load() async {
    status = InsightsStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.getMonthlyInsights();
      insights = snapshot.insights;
      fetchedAt = snapshot.fetchedAt;
      status = snapshot.insights.categories.isEmpty
          ? InsightsStatus.empty
          : snapshot.isStale
              ? InsightsStatus.offlineStale
              : InsightsStatus.loaded;
    } on Object {
      status = InsightsStatus.error;
      errorMessage = 'No pudimos cargar tus insights.';
    }
    notifyListeners();
  }
}
