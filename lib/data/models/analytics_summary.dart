import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyTotal {
  final DateTime month;
  final double value;

  MonthlyTotal({
    required this.month,
    required this.value,
  });

  factory MonthlyTotal.fromMap(Map<String, dynamic> map) {
    final monthKey = (map['month'] as String?) ?? '';
    final parsedMonth = monthKey.isNotEmpty
        ? DateTime.parse('$monthKey-01')
        : DateTime.now();
    return MonthlyTotal(
      month: parsedMonth,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AnalyticsForecast {
  final double nextMonth;
  final double trendPercent;
  final double seasonalFactor;
  final String explanation;

  AnalyticsForecast({
    required this.nextMonth,
    required this.trendPercent,
    required this.seasonalFactor,
    required this.explanation,
  });

  factory AnalyticsForecast.fromMap(Map<String, dynamic> map) {
    return AnalyticsForecast(
      nextMonth: (map['nextMonth'] as num?)?.toDouble() ?? 0.0,
      trendPercent: (map['trendPercent'] as num?)?.toDouble() ?? 0.0,
      seasonalFactor: (map['seasonalFactor'] as num?)?.toDouble() ?? 1.0,
      explanation: (map['explanation'] as String?) ?? '',
    );
  }
}

class AnalyticsInsight {
  final String title;
  final String detail;
  final String type;

  AnalyticsInsight({
    required this.title,
    required this.detail,
    required this.type,
  });

  factory AnalyticsInsight.fromMap(Map<String, dynamic> map) {
    return AnalyticsInsight(
      title: (map['title'] as String?) ?? '',
      detail: (map['detail'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'general',
    );
  }
}

class AnalyticsSummary {
  final List<MonthlyTotal> monthlyTotals;
  final AnalyticsForecast? forecast;
  final List<AnalyticsInsight> insights;
  final DateTime? updatedAt;
  final int windowMonths;

  AnalyticsSummary({
    required this.monthlyTotals,
    required this.forecast,
    required this.insights,
    required this.updatedAt,
    required this.windowMonths,
  });

  factory AnalyticsSummary.fromMap(Map<String, dynamic> map) {
    final totals = (map['monthlyTotals'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MonthlyTotal.fromMap)
        .toList();
    totals.sort((a, b) => a.month.compareTo(b.month));

    final forecastMap = map['forecast'] as Map<String, dynamic>?;
    final insights = (map['insights'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AnalyticsInsight.fromMap)
        .toList();

    final updatedAtValue = map['updatedAt'];
    final updatedAt = updatedAtValue is Timestamp
        ? updatedAtValue.toDate()
        : updatedAtValue is DateTime
            ? updatedAtValue
            : null;

    return AnalyticsSummary(
      monthlyTotals: totals,
      forecast: forecastMap == null ? null : AnalyticsForecast.fromMap(forecastMap),
      insights: insights,
      updatedAt: updatedAt,
      windowMonths: (map['windowMonths'] as num?)?.toInt() ?? 12,
    );
  }
}
