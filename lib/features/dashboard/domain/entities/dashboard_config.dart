enum DashboardSectionType {
  balance,
  quickActions,
  products,
  recentTransactions,
  insight,
  exchangePromo,
  serviceStatus,
}

class DashboardSection {
  const DashboardSection({
    required this.id,
    required this.type,
    required this.order,
    required this.payload,
  });

  final String id;
  final DashboardSectionType type;
  final int order;
  final Map<String, dynamic> payload;
}

class DashboardConfig {
  const DashboardConfig({
    required this.schemaVersion,
    required this.segment,
    required this.sections,
  });

  final int schemaVersion;
  final String segment;
  final List<DashboardSection> sections;

  factory DashboardConfig.fromMap(Map<String, dynamic> map) {
    final rawSections = map['sections'];
    if (map['schemaVersion'] is! int ||
        map['segment'] is! String ||
        rawSections is! List) {
      throw const FormatException('Invalid dashboard configuration.');
    }

    final sections = <DashboardSection>[];
    for (final raw in rawSections) {
      if (raw is! Map) continue;
      final section = Map<String, dynamic>.from(raw);
      final type = _parseType(section['type'] as String?);
      final payload = section['payload'];
      if (type == null ||
          section['id'] is! String ||
          section['order'] is! int ||
          payload is! Map) {
        continue;
      }
      sections.add(
        DashboardSection(
          id: section['id'] as String,
          type: type,
          order: section['order'] as int,
          payload: Map<String, dynamic>.from(payload),
        ),
      );
    }
    sections.sort((a, b) => a.order.compareTo(b.order));
    return DashboardConfig(
      schemaVersion: map['schemaVersion'] as int,
      segment: map['segment'] as String,
      sections: sections,
    );
  }

  static DashboardSectionType? _parseType(String? value) {
    return switch (value) {
      'balance' => DashboardSectionType.balance,
      'quick_actions' => DashboardSectionType.quickActions,
      'products' => DashboardSectionType.products,
      'recent_transactions' => DashboardSectionType.recentTransactions,
      'insight' => DashboardSectionType.insight,
      'exchange_promo' => DashboardSectionType.exchangePromo,
      'service_status' => DashboardSectionType.serviceStatus,
      _ => null,
    };
  }
}
