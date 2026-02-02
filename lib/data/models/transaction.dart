import 'package:cloud_firestore/cloud_firestore.dart';
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
  final String walletId;
  final String? note;
  final List<String>? tags;
  final String currencyCode;
  final double? originalAmount;
  final double? exchangeRate;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.icon,
    required this.date,
    required this.walletId,
    this.note,
    this.tags,
    this.currencyCode = 'USD',
    this.originalAmount,
    this.exchangeRate,
  });

  // UI HELPERS (Restored & Fixed)

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  String get formattedAmount {
    final displayAmount = originalAmount ?? amount;
    final symbol = _currencySymbol(currencyCode);
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(displayAmount);
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

  // Restored: Logic for "Just now", "2h ago", etc.
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

  // Restored: Logic for grouping headers (Today, Yesterday)
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
      return DateFormat('EEEE').format(date); // Day of week (e.g. Monday)
    } else {
      return DateFormat('MMM dd').format(date); // Month and day (e.g. Jul 25)
    }
  }

  // 2. DATABASE HELPERS (For Firestore)

  // Convert Object -> Map (For writing to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'description': description,
      'category': category,
      'icon': icon,
      'date': Timestamp.fromDate(date), // Writes as Timestamp for Firestore
      'walletId': walletId,
      'note': note,
      'tags': tags,
      'currencyCode': currencyCode,
      'originalAmount': originalAmount,
      'exchangeRate': exchangeRate,
    };
  }

  // Convert Object -> Map (For local storage - without Timestamp)
  Map<String, dynamic> toMapForLocal() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'description': description,
      'category': category,
      'icon': icon,
      'date': date.millisecondsSinceEpoch, // Use milliseconds for SQLite
      'walletId': walletId,
      'note': note,
      'tags': tags,
      'currencyCode': currencyCode,
      'originalAmount': originalAmount,
      'exchangeRate': exchangeRate,
    };
  }

  // Convert Map -> Object (For reading from Firebase)
  factory Transaction.fromMap(Map<String, dynamic> map, String docId) {
    return Transaction(
      id: docId,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      icon: map['icon'] ?? '💰',
      // Handles Timestamp, milliseconds, or ISO string
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : (map['date'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
              : DateTime.parse(map['date'].toString())),
      walletId: map['walletId'] ?? '',
      note: map['note'],
      tags: map['tags'] is List ? List<String>.from(map['tags']) : [],
      currencyCode: map['currencyCode'] ?? 'USD',
      originalAmount: map['originalAmount'] != null
          ? (map['originalAmount'] as num).toDouble()
          : null,
      exchangeRate: map['exchangeRate'] != null
          ? (map['exchangeRate'] as num).toDouble()
          : null,
    );
  }

  String _currencySymbol(String code) {
    switch (code) {
      case 'LBP':
        return 'LBP ';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'USD':
      default:
        return '\$';
    }
  }

  // Optional: CopyWith (Useful for editing transactions later)
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
}
