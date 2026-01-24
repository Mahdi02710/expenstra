import 'transaction.dart';

enum RecurrencePeriod {
  daily,
  weekly,
  monthly,
  yearly,
}

class RecurringPayment {
  final String id;
  final String name;
  final double amount;
  final TransactionType type;
  final String category;
  final String icon;
  final String walletId;
  final String? note;
  final RecurrencePeriod period;
  final DateTime startDate;
  final DateTime nextRunAt;
  final DateTime? lastRunAt;
  final bool isActive;

  RecurringPayment({
    required this.id,
    required this.name,
    required this.amount,
    this.type = TransactionType.expense,
    required this.category,
    required this.icon,
    required this.walletId,
    required this.period,
    required this.startDate,
    required this.nextRunAt,
    this.note,
    this.lastRunAt,
    this.isActive = true,
  });

  RecurringPayment copyWith({
    String? id,
    String? name,
    double? amount,
    TransactionType? type,
    String? category,
    String? icon,
    String? walletId,
    String? note,
    RecurrencePeriod? period,
    DateTime? startDate,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    bool? isActive,
  }) {
    return RecurringPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      walletId: walletId ?? this.walletId,
      note: note ?? this.note,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      isActive: isActive ?? this.isActive,
    );
  }

  DateTime nextDate(DateTime from) {
    switch (period) {
      case RecurrencePeriod.daily:
        return from.add(const Duration(days: 1));
      case RecurrencePeriod.weekly:
        return from.add(const Duration(days: 7));
      case RecurrencePeriod.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurrencePeriod.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  Map<String, dynamic> toMapForLocal() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type.name,
      'category': category,
      'icon': icon,
      'walletId': walletId,
      'note': note,
      'period': period.name,
      'startDate': startDate.millisecondsSinceEpoch,
      'nextRunAt': nextRunAt.millisecondsSinceEpoch,
      'lastRunAt': lastRunAt?.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory RecurringPayment.fromMap(Map<String, dynamic> map) {
    return RecurringPayment(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: map['category'] as String,
      icon: map['icon'] as String,
      walletId: map['walletId'] as String,
      note: map['note'] as String?,
      period: RecurrencePeriod.values.firstWhere(
        (p) => p.name == map['period'],
        orElse: () => RecurrencePeriod.monthly,
      ),
      startDate: DateTime.fromMillisecondsSinceEpoch(
        map['startDate'] as int,
      ),
      nextRunAt: DateTime.fromMillisecondsSinceEpoch(
        map['nextRunAt'] as int,
      ),
      lastRunAt: map['lastRunAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastRunAt'] as int)
          : null,
      isActive: (map['isActive'] as int? ?? 1) == 1,
    );
  }
}
