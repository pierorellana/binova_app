import '../entities/dashboard_config.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.config,
    required this.fetchedAt,
    required this.isStale,
  });

  final DashboardConfig config;
  final DateTime fetchedAt;
  final bool isStale;
}

abstract interface class DashboardRepository {
  Future<DashboardSnapshot> getDashboard();
}
