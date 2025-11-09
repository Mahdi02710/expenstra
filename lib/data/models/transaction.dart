import 'package:intl/intl.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final String category;
  final String icon;
  final DateTime date;
  final String? walletId;
  final String? note;
  final List<String>? tags;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.icon,
    required this.date,
    this.walletId,
    this.note,
    this.tags,
  });

  // Helper getters
  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  String get formattedAmount {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  String get formattedAmountWithSign {
    final sign = isIncome ? '+' : '-';
    return '$sign$formattedAmount';
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String get formattedTime {
    return DateFormat('HH:mm').format(date);
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return formattedDate;
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day of week
    } else {
      return DateFormat('MMM dd').format(date); // Month and day
    }
  }

  // Factory methods
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      amount: json['amount'].toDouble(),
      description: json['description'],
      category: json['category'],
      icon: json['icon'],
      date: DateTime.parse(json['date']),
      walletId: json['walletId'],
      note: json['note'],
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'amount': amount,
      'description': description,
      'category': category,
      'icon': icon,
      'date': date.toIso8601String(),
      'walletId': walletId,
      'note': note,
      'tags': tags,
    };
  }

  // Copy with method
  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? description,
    String? category,
    String? icon,
    DateTime? date,
    String? walletId,
    String? note,
    List<String>? tags,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      note: note ?? this.note,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, description: $description, date: $date)';
  }
}