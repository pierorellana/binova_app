import '../../../accounts/domain/entities/money.dart';

class InsightCategory {
  const InsightCategory({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  final String category;
  final Money amount;
  final String percentage;

  factory InsightCategory.fromMap(Map<String, dynamic> map) {
    if (map['category'] is! String ||
        map['amount'] is! Map ||
        map['percentage'] is! String) {
      throw const FormatException('Invalid insight category.');
    }
    return InsightCategory(
      category: map['category'] as String,
      amount: Money.fromMap(Map<String, dynamic>.from(map['amount'] as Map)),
      percentage: map['percentage'] as String,
    );
  }
}


class InsightTrendPoint {
  const InsightTrendPoint({required this.start, required this.totalExpense});

  final DateTime start;
  final Money totalExpense;

  factory InsightTrendPoint.fromMap(Map<String, dynamic> map) {
    final start = DateTime.tryParse(map['start'] as String? ?? '');
    if (start == null || map['totalExpense'] is! Map) {
      throw const FormatException('Invalid insight trend point.');
    }
    return InsightTrendPoint(
      start: start,
      totalExpense: Money.fromMap(Map<String, dynamic>.from(map['totalExpense'] as Map)),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'start': start.toIso8601String().substring(0, 10),
        'totalExpense': totalExpense.toMap(),
      };
}

class Insights {
  const Insights({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.comparisonPercentage,
    required this.categories,
    this.trend = const <InsightTrendPoint>[],
  });

  final String period;
  final Money totalIncome;
  final Money totalExpense;
  final String? comparisonPercentage;
  final List<InsightCategory> categories;


  final List<InsightTrendPoint> trend;

  factory Insights.fromMap(Map<String, dynamic> map) {
    final rawCategories = map['categories'];
    if (map['period'] is! String ||
        map['totalIncome'] is! Map ||
        map['totalExpense'] is! Map ||
        rawCategories is! List) {
      throw const FormatException('Invalid insights.');
    }
    return Insights(
      period: map['period'] as String,
      totalIncome:
          Money.fromMap(Map<String, dynamic>.from(map['totalIncome'] as Map)),
      totalExpense:
          Money.fromMap(Map<String, dynamic>.from(map['totalExpense'] as Map)),
      comparisonPercentage: map['comparisonPercentage'] as String?,
      categories: rawCategories
          .whereType<Map>()
          .map((item) =>
              InsightCategory.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      trend: (map['trend'] is List ? map['trend'] as List : const [])
          .whereType<Map>()
          .map((item) => InsightTrendPoint.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'period': period,
        'totalIncome': totalIncome.toMap(),
        'totalExpense': totalExpense.toMap(),
        'comparisonPercentage': comparisonPercentage,
        'categories': categories
            .map((category) => <String, dynamic>{
                  'category': category.category,
                  'amount': category.amount.toMap(),
                  'percentage': category.percentage,
                })
            .toList(),
        'trend': trend.map((point) => point.toMap()).toList(),
      };
}
