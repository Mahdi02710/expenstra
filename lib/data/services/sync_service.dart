// ignore_for_file: avoid_print, unrelated_type_equality_checks

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'local_database_service.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/budget.dart';

class SyncService {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final ApiService _apiService = ApiService();
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  static const _transactionsLastSyncKey = 'sync_last_transactions';
  static const _walletsLastSyncKey = 'sync_last_wallets';
  static const _budgetsLastSyncKey = 'sync_last_budgets';

  Future<void> resetSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsLastSyncKey);
    await prefs.remove(_walletsLastSyncKey);
    await prefs.remove(_budgetsLastSyncKey);
  }

  Future<void> syncAll() async {
    if (!isAuthenticated) return;

    final online = await isOnline();
    if (!online) {
      print('No internet connection. Using local data only.');
      return;
    }

    try {
      await _syncTransactions();
      await _syncWallets();
      await _syncBudgets();
    } catch (e) {
      print('Error syncing data: $e');
    }
  }


  Future<void> _syncTransactions() async {
    final unsyncedTransactions = await _localDb.getUnsyncedTransactions();
    final lastSync = await _getLastSync(_transactionsLastSyncKey);
    final payload = {
      'items': unsyncedTransactions.map(_transactionToApi).toList(),
      'lastSync': lastSync,
    };
    final response =
        await _apiService.post('/sync/transactions', payload) as Map;
    final upserts = _normalizeList(response['upserts']);
    for (final item in upserts) {
      final transaction = Transaction.fromMap(item, item['id'] as String);
      await _localDb.insertTransaction(transaction, synced: true);
    }
    for (final transaction in unsyncedTransactions) {
      await _localDb.markTransactionSynced(transaction.id);
    }
    await _setLastSync(
      _transactionsLastSyncKey,
      response['serverTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _syncWallets() async {
    final wallets = await _localDb.getWallets();
    final lastSync = await _getLastSync(_walletsLastSyncKey);
    final payload = {
      'items': wallets.map(_walletToApi).toList(),
      'lastSync': lastSync,
    };
    final response = await _apiService.post('/sync/wallets', payload) as Map;
    final upserts = _normalizeList(response['upserts']);
    for (final item in upserts) {
      final wallet = Wallet.fromMap(item, item['id'] as String);
      await _localDb.insertWallet(wallet, synced: true);
    }
    await _setLastSync(
      _walletsLastSyncKey,
      response['serverTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _syncBudgets() async {
    final budgets = await _localDb.getBudgets();
    final lastSync = await _getLastSync(_budgetsLastSyncKey);
    final payload = {
      'items': budgets.map(_budgetToApi).toList(),
      'lastSync': lastSync,
    };
    final response = await _apiService.post('/sync/budgets', payload) as Map;
    final upserts = _normalizeList(response['upserts']);
    for (final item in upserts) {
      final budget = Budget.fromMap(item, item['id'] as String);
      await _localDb.insertBudget(budget, synced: true);
    }
    await _setLastSync(
      _budgetsLastSyncKey,
      response['serverTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }


  /// Syncs a single transaction
  Future<void> syncTransaction(Transaction transaction) async {
    // Save to local DB first (always)
    await _localDb.insertTransaction(transaction, synced: false);

    // If online and authenticated, also save to Firebase
    if (isAuthenticated && await isOnline()) {
      try {
        await _syncTransactions();
      } catch (e) {
        print('Error syncing transaction to backend: $e');
        // Transaction remains in local DB with synced=false
      }
    }
  }

  /// Syncs a single wallet
  Future<void> syncWallet(Wallet wallet) async {
    await _localDb.insertWallet(wallet, synced: false);

    if (isAuthenticated && await isOnline()) {
      try {
        await _syncWallets();
      } catch (e) {
        print('Error syncing wallet to backend: $e');
      }
    }
  }

  /// Syncs a single budget
  Future<void> syncBudget(Budget budget) async {
    await _localDb.insertBudget(budget, synced: false);

    if (isAuthenticated && await isOnline()) {
      try {
        await _syncBudgets();
      } catch (e) {
        print('Error syncing budget to backend: $e');
      }
    }
  }

  /// Deletes a transaction from both local and Firebase
  Future<void> deleteTransaction(String id) async {
    await _localDb.deleteTransaction(id, synced: false);

    if (isAuthenticated && await isOnline()) {
      try {
        await _apiService.delete('/sync/transactions/$id');
        await _localDb.markTransactionSynced(id);
      } catch (e) {
        print('Error deleting transaction from backend: $e');
      }
    }
  }

  /// Deletes a wallet from both local and Firebase
  Future<void> deleteWallet(String id) async {
    await _localDb.deleteWallet(id, synced: false);

    if (isAuthenticated && await isOnline()) {
      try {
        await _apiService.delete('/sync/wallets/$id');
        await _localDb.markWalletSynced(id);
      } catch (e) {
        print('Error deleting wallet from backend: $e');
      }
    }
  }

  /// Deletes a budget from both local and Firebase
  Future<void> deleteBudget(String id) async {
    await _localDb.deleteBudget(id, synced: false);

    if (isAuthenticated && await isOnline()) {
      try {
        await _apiService.delete('/sync/budgets/$id');
        await _localDb.markBudgetSynced(id);
      } catch (e) {
        print('Error deleting budget from backend: $e');
      }
    }
  }

  Future<int?> _getLastSync(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<void> _setLastSync(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Map<String, dynamic> _transactionToApi(Transaction transaction) {
    return {
      'id': transaction.id,
      'type': transaction.type.name,
      'amount': transaction.amount,
      'currencyCode': transaction.currencyCode,
      'originalAmount': transaction.originalAmount,
      'exchangeRate': transaction.exchangeRate,
      'description': transaction.description,
      'category': transaction.category,
      'icon': transaction.icon,
      'date': transaction.date.millisecondsSinceEpoch,
      'walletId': transaction.walletId,
      'note': transaction.note,
      'tags': transaction.tags,
      'createdAt': transaction.date.millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _walletToApi(Wallet wallet) {
    return {
      'id': wallet.id,
      'name': wallet.name,
      'balance': wallet.balance,
      'type': wallet.type.name,
      'icon': wallet.icon,
      'color': wallet.color,
      'accountNumber': wallet.accountNumber,
      'bankName': wallet.bankName,
      'creditLimit': wallet.creditLimit,
      'isActive': wallet.isActive,
      'createdAt': wallet.createdAt.millisecondsSinceEpoch,
      'lastTransactionDate': wallet.lastTransactionDate?.millisecondsSinceEpoch,
      'isMonthlyRollover': wallet.isMonthlyRollover,
      'rolloverToWalletId': wallet.rolloverToWalletId,
      'lastRolloverAt': wallet.lastRolloverAt?.millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _budgetToApi(Budget budget) {
    return {
      'id': budget.id,
      'name': budget.name,
      'spent': budget.spent,
      'limit': budget.limit,
      'icon': budget.icon,
      'color': budget.color,
      'period': budget.period.name,
      'category': budget.category,
      'startDate': budget.startDate.millisecondsSinceEpoch,
      'endDate': budget.endDate.millisecondsSinceEpoch,
      'isActive': budget.isActive,
      'alertThreshold': budget.alertThreshold,
      'includedCategories': budget.includedCategories,
      'createdAt': budget.startDate.millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  List<Map<String, dynamic>> _normalizeList(dynamic items) {
    if (items is List) {
      return items
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return [];
  }


  /// Gets transactions stream from local DB, with periodic sync
  Stream<List<Transaction>> getTransactionsStream() async* {
    final localTransactions =
        await _localDb.getTransactions();
    yield localTransactions;

    // Periodically sync and update
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      if (isAuthenticated && await isOnline()) {
        await syncAll();
      }
      final updatedTransactions =
          await _localDb.getTransactions();
      yield updatedTransactions;
    }
  }

  /// Gets wallets stream from local DB, with periodic sync
  Stream<List<Wallet>> getWalletsStream() async* {
    final localWallets = await _localDb.getWallets();
    yield localWallets;

    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      if (isAuthenticated && await isOnline()) {
        await syncAll();
      }
      final updatedWallets = await _localDb.getWallets();
      yield updatedWallets;
    }
  }

  /// Gets budgets stream from local DB, with periodic sync
  Stream<List<Budget>> getBudgetsStream() async* {
    final localBudgets = await _localDb.getBudgets();
    yield localBudgets;

    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      if (isAuthenticated && await isOnline()) {
        await syncAll();
      }
      final updatedBudgets = await _localDb.getBudgets();
      yield updatedBudgets;
    }
  }
}
