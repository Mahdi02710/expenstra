import 'package:intl/intl.dart';

enum BudgetPeriod { weekly, monthly, yearly }

class Budget {
  final String id;
  final String name;
  final double spent;
  final double limit;
  final String icon;
  final String color;
  final BudgetPeriod period;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final double? alertThreshold; // Percentage (0.0 - 1.0)
  final List<String>? includedCategories;

  const Budget({
    required this.id,
    required this.name,
    required this.spent,
    required this.limit,
    required this.icon,
    required this.color,
    required this.period,
    required this.category,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.alertThreshold,
    this.includedCategories,
  });

  // Helper getters
  double get percentage => limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
  double get remaining => (limit - spent).clamp(0.0, double.infinity);
  bool get isOverBudget => spent > limit;
  bool get isNearLimit => alertThreshold != null && percentage >= alertThreshold!;

  String get periodLabel {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Weekly Budget';
      case BudgetPeriod.monthly:
        return 'Monthly Budget';
      case BudgetPeriod.yearly:
        return 'Yearly Budget';
    }
  }

  String get periodShortLabel {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  String get status {
    if (isOverBudget) {
      return 'Over Budget';
    } else if (percentage > 0.9) {
      return 'Almost Exceeded';
    } else if (percentage > 0.7) {
      return 'On Track';
    } else if (percentage > 0.5) {
      return 'Good Progress';
    } else {
      return 'Well Within Budget';
    }
  }

  String get statusEmoji {
    if (isOverBudget) {
      return '🚨';
    } else if (percentage > 0.9) {
      return '⚠️';
    } else if (percentage > 0.7) {
      return '📊';
    } else if (percentage > 0.5) {
      return '✅';
    } else {
      return '🎯';
    }
  }

  String get formattedSpent {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(spent);
  }

  String get formattedLimit {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(limit);
  }

  String get formattedRemaining {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(remaining);
  }

  String get formattedPercentage {
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }

  String get periodProgress {
    final now = DateTime.now();
    if (now.isAfter(endDate)) {
      return 'Period Ended';
    }
    
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = now.difference(startDate).inDays;
    final progressPercentage = totalDays > 0 ? (elapsedDays / totalDays * 100).clamp(0.0, 100.0) : 0.0;
    
    return '${progressPercentage.toStringAsFixed(0)}% through period';
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  String get daysRemainingText {
    final days = daysRemaining;
    if (days == 0) {
      return 'Ends today';
    } else if (days == 1) {
      return '1 day remaining';
    } else {
      return '$days days remaining';
    }
  }

  double get dailySpendingRate {
    final totalDays = endDate.difference(startDate).inDays;
    return totalDays > 0 ? spent / totalDays : 0.0;
  }

  double get recommendedDailySpending {
    final remainingDays = daysRemaining;
    return remainingDays > 0 ? remaining / remainingDays : 0.0;
  }

  String get spendingAdvice {
    if (isOverBudget) {
      return 'You\'ve exceeded your budget. Consider reducing spending in this category.';
    }
    
    final recommended = recommendedDailySpending;
    final current = dailySpendingRate;
    
    if (current > recommended * 1.2) {
      return 'You\'re spending faster than recommended. Consider slowing down.';
    } else if (current < recommended * 0.8) {
      return 'Great job! You\'re spending below the recommended rate.';
    } else {
      return 'You\'re on track with your spending goals.';
    }
  }

  // Factory methods
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      name: json['name'],
      spent: json['spent'].toDouble(),
      limit: json['limit'].toDouble(),
      icon: json['icon'],
      color: json['color'],
      period: BudgetPeriod.values.firstWhere(
        (e) => e.toString() == json['period'],
      ),
      category: json['category'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'] ?? true,
      alertThreshold: json['alertThreshold']?.toDouble(),
      includedCategories: json['includedCategories'] != null
          ? List<String>.from(json['includedCategories'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'spent': spent,
      'limit': limit,
      'icon': icon,
      'color': color,
      'period': period.toString(),
      'category': category,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'alertThreshold': alertThreshold,
      'includedCategories': includedCategories,
    };
  }

  // Copy with method
  Budget copyWith({
    String? id,
    String? name,
    double? spent,
    double? limit,
    String? icon,
    String? color,
    BudgetPeriod? period,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    double? alertThreshold,
    List<String>? includedCategories,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      spent: spent ?? this.spent,
      limit: limit ?? this.limit,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      period: period ?? this.period,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      includedCategories: includedCategories ?? this.includedCategories,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Budget(id: $id, name: $name, spent: $spent, limit: $limit, period: $period)';
  }
}