// ignore_for_file: avoid_print, avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart' as model;
import '../models/wallet.dart' as wallet_model;
import '../models/budget.dart' as budget_model;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Stream<List<model.Transaction>> getTransactions() {
    if (_userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) {
                  try {
                    return model.Transaction.fromMap(doc.data(), doc.id);
                  } catch (e) {
                    print('Error parsing transaction ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<model.Transaction>()
                .toList();
          } catch (e) {
            print('Error processing transactions: $e');
            return <model.Transaction>[];
          }
        })
        .handleError((error) {
          print('Error loading transactions: $error');
        });
  }

  Future<void> addTransaction(model.Transaction transaction) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .add(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  // Calculate total balance from transactions
  Future<double> calculateTotalBalance() async {
    if (_userId == null) return 0.0;

    try {
      final snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .get();

      double balance = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String;
        final amount = (data['amount'] as num).toDouble();

        if (type == 'income') {
          balance += amount;
        } else if (type == 'expense') {
          balance -= amount;
        }
      }

      return balance;
    } catch (e) {
      print('Error calculating total balance: $e');
      return 0.0;
    }
  }

  // Calculate total income for a period
  Future<double> calculateTotalIncome({Duration? period}) async {
    if (_userId == null) return 0.0;

    try {
      var query = _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .where('type', isEqualTo: 'income');

      if (period != null) {
        final cutoff = Timestamp.fromDate(DateTime.now().subtract(period));
        query = query.where('date', isGreaterThanOrEqualTo: cutoff);
      }

      final snapshot = await query.get();

      return snapshot.docs.fold<double>(0.0, (sum, doc) {
        final amount = (doc.data()['amount'] as num).toDouble();
        return sum + amount;
      });
    } catch (e) {
      print('Error calculating total income: $e');
      return 0.0;
    }
  }

  // Calculate total expenses for a period
  Future<double> calculateTotalExpenses({Duration? period}) async {
    if (_userId == null) return 0.0;

    try {
      var query = _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .where('type', isEqualTo: 'expense');

      if (period != null) {
        final cutoff = Timestamp.fromDate(DateTime.now().subtract(period));
        query = query.where('date', isGreaterThanOrEqualTo: cutoff);
      }

      final snapshot = await query.get();

      return snapshot.docs.fold<double>(0.0, (sum, doc) {
        final amount = (doc.data()['amount'] as num).toDouble();
        return sum + amount;
      });
    } catch (e) {
      print('Error calculating total expenses: $e');
      return 0.0;
    }
  }

  // Wallet operations
  Stream<List<wallet_model.Wallet>> getWallets() {
    if (_userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_userId)
        .collection('wallets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) {
                  try {
                    return wallet_model.Wallet.fromMap(doc.data(), doc.id);
                  } catch (e) {
                    print('Error parsing wallet ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<wallet_model.Wallet>()
                .toList();
          } catch (e) {
            print('Error processing wallets: $e');
            return <wallet_model.Wallet>[];
          }
        })
        .handleError((error) {
          print('Error loading wallets: $error');
        });
  }

  Future<void> addWallet(wallet_model.Wallet wallet) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('wallets')
        .doc(wallet.id)
        .set(wallet.toMap());
  }

  Future<void> updateWallet(wallet_model.Wallet wallet) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('wallets')
        .doc(wallet.id)
        .update(wallet.toMap());
  }

  Future<void> deleteWallet(String walletId) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('wallets')
        .doc(walletId)
        .delete();
  }

  // Calculate wallet balance from transactions
  Future<double> calculateWalletBalance(String walletId) async {
    if (_userId == null) return 0.0;

    try {
      final snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .where('walletId', isEqualTo: walletId)
          .get();

      double balance = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String;
        final amount = (data['amount'] as num).toDouble();

        if (type == 'income') {
          balance += amount;
        } else if (type == 'expense') {
          balance -= amount;
        }
      }

      return balance;
    } catch (e) {
      print('Error calculating wallet balance: $e');
      return 0.0;
    }
  }

  // Budget operations
  Stream<List<budget_model.Budget>> getBudgets() {
    if (_userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .where('isActive', isEqualTo: true)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) {
                  try {
                    return budget_model.Budget.fromMap(doc.data(), doc.id);
                  } catch (e) {
                    print('Error parsing budget ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<budget_model.Budget>()
                .toList();
          } catch (e) {
            print('Error processing budgets: $e');
            return <budget_model.Budget>[];
          }
        })
        .handleError((error) {
          print('Error loading budgets: $error');
        });
  }

  Future<void> addBudget(budget_model.Budget budget) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budget.id)
        .set(budget.toMap());
  }

  Future<void> updateBudget(budget_model.Budget budget) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budget.id)
        .update(budget.toMap());
  }

  Future<void> deleteBudget(String budgetId) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }

  // Calculate budget spent amount from transactions
  Future<double> calculateBudgetSpent(
    String category,
    DateTime startDate,
    DateTime endDate,
    List<String>? includedCategories,
  ) async {
    if (_userId == null) return 0.0;

    try {
      final categories = includedCategories ?? [category];
      
      final snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .where('category', whereIn: categories)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs.fold<double>(0.0, (sum, doc) {
        final amount = (doc.data()['amount'] as num).toDouble();
        return sum + amount;
      });
    } catch (e) {
      print('Error calculating budget spent: $e');
      return 0.0;
    }
  }
}
