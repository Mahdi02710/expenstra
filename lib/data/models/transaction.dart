import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { expense, income }

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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'description': description,
      'category': category,
      'icon': icon,
      'date': Timestamp.fromDate(date),
      'walletId': walletId,
      'note': note,
      'tags': tags,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map, String docId) {
    return Transaction(
      id: docId,
      type: TransactionType.values.byName(map['type']),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      icon: map['icon'] ?? '💰',
      date: (map['date'] as Timestamp).toDate(),
      walletId: map['walletId'] ?? '',
      note: map['note'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}
