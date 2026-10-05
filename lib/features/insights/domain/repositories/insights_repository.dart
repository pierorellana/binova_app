import '../entities/insights.dart';

class InsightsSnapshot {
  const InsightsSnapshot({
    required this.insights,
    required this.fetchedAt,
    required this.isStale,
  });

  final Insights insights;
  final DateTime fetchedAt;
  final bool isStale;
}

abstract interface class InsightsRepository {
  Future<InsightsSnapshot> getMonthlyInsights();
}
