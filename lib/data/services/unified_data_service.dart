import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_database_service.dart';
import 'sync_service.dart';
import 'firestore_service.dart';
import 'settings_service.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/budget.dart';

/// Unified service that handles both local SQLite and Firebase storage
/// Reads from local DB first (fast, works offline), syncs with Firebase in background
class UnifiedDataService {
  static final UnifiedDataService _instance = UnifiedDataService._internal();
  factory UnifiedDataService() => _instance;
  UnifiedDataService._internal();

  final LocalDatabaseService _localDb = LocalDatabaseService();
  final SyncService _syncService = SyncService();
  final FirestoreService _firestoreService = FirestoreService();
  final SettingsService _settingsService = SettingsService();

  final _transactionsController =
      StreamController<List<Transaction>>.broadcast();
  final _walletsController = StreamController<List<Wallet>>.broadcast();
  final _budgetsController = StreamController<List<Budget>>.broadcast();

  Timer? _syncTimer;
  bool _isInitialized = false;

  /// Initialize the service - loads local data and starts syncing
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final autoSync = _settingsService.autoSyncEnabled.value;
      if (autoSync && FirebaseAuth.instance.currentUser != null) {
        await _syncService.syncAll();
        _startPeriodicSync();
      }

      await _processMonthlyWalletRollover();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing UnifiedDataService: $e');
      // Don't throw - allow app to continue with local data only
      // Still mark as initialized so app can proceed
      _isInitialized = true;
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_settingsService.autoSyncEnabled.value) {
        return;
      }
      if (FirebaseAuth.instance.currentUser != null) {
        _syncService.syncAll();
      }
    });
  }

  void dispose() {
    _syncTimer?.cancel();
    _transactionsController.close();
    _walletsController.close();
    _budgetsController.close();
  }

  Future<void> _processMonthlyWalletRollover() async {
    final wallets = await _localDb.getWallets();
    if (wallets.isEmpty) return;

    final now = DateTime.now();
    for (final wallet in wallets) {
      if (!wallet.isMonthlyRollover) {
        continue;
      }
      final last = wallet.lastRolloverAt;
      if (last != null && last.year == now.year && last.month == now.month) {
        continue;
      }

      final balance = await _localDb.calculateWalletBalance(wallet.id);
      Wallet? targetWallet;
      if (wallet.rolloverToWalletId != null) {
        for (final w in wallets) {
          if (w.id == wallet.rolloverToWalletId) {
            targetWallet = w;
            break;
          }
        }
      }

      if (targetWallet == null) {
        for (final w in wallets) {
          if (w.type == WalletType.savings) {
            targetWallet = w;
            break;
          }
        }
      }

      if (targetWallet == null) {
        final newSavings = Wallet(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Savings',
          balance: 0,
          type: WalletType.savings,
          icon: '💰',
          color: 'green',
          accountNumber: 'SAVINGS',
          createdAt: now,
        );
        await addWallet(newSavings);
        targetWallet = newSavings;
      }

      if (balance > 0) {
        final expenseTx = Transaction(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: TransactionType.expense,
          amount: balance,
          description: 'Monthly rollover to ${targetWallet.name}',
          category: 'Rollover',
          icon: '🔁',
          date: now,
          walletId: wallet.id,
          currencyCode: _settingsService.defaultCurrency.value,
        );
        final incomeTx = Transaction(
          id: (DateTime.now().microsecondsSinceEpoch + 1).toString(),
          type: TransactionType.income,
          amount: balance,
          description: 'Monthly rollover from ${wallet.name}',
          category: 'Rollover',
          icon: '🔁',
          date: now,
          walletId: targetWallet.id,
          currencyCode: _settingsService.defaultCurrency.value,
        );
        await addTransaction(expenseTx);
        await addTransaction(incomeTx);
      }

      final updatedWallet = wallet.copyWith(
        rolloverToWalletId: targetWallet.id,
        lastRolloverAt: now,
      );
      await updateWallet(updatedWallet);
    }
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  /// Get transactions stream - reads from local DB, syncs in background
  Stream<List<Transaction>> getTransactions() {
    if (!_transactionsController.isClosed) {
      _transactionsController.add([]);
    }
    // Emit initial data from local DB
    _localDb.getTransactions().then((transactions) {
      if (!_transactionsController.isClosed) {
        _transactionsController.add(transactions);
      }
    }).catchError((error) {
      if (!_transactionsController.isClosed) {
        _transactionsController.addError(error);
      }
    });

    // Periodically update from local DB
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_transactionsController.isClosed) {
        timer.cancel();
        return;
      }
      try {
        final transactions = await _localDb.getTransactions();
        if (!_transactionsController.isClosed) {
          _transactionsController.add(transactions);
        } else {
          timer.cancel();
        }
      } catch (error) {
        if (!_transactionsController.isClosed) {
          _transactionsController.addError(error);
        }
      }
    });

    return _transactionsController.stream;
  }

  /// Add transaction - saves to local DB immediately, syncs to Firebase in background
  Future<void> addTransaction(Transaction transaction) async {
    await _syncService.syncTransaction(transaction);
    // Trigger stream update
    final transactions = await _localDb.getTransactions();
    _transactionsController.add(transactions);
  }

  /// Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await _localDb.updateTransaction(transaction, synced: false);
    if (FirebaseAuth.instance.currentUser != null) {
      await _syncService.syncTransaction(transaction);
    }
    final transactions = await _localDb.getTransactions();
    _transactionsController.add(transactions);
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    await _syncService.deleteTransaction(id);
    final transactions = await _localDb.getTransactions();
    _transactionsController.add(transactions);
  }

  // ==========================================
  // WALLETS
  // ==========================================

  /// Get wallets stream
  Stream<List<Wallet>> getWallets() {
    if (!_walletsController.isClosed) {
      _walletsController.add([]);
    }
    _localDb.getWallets().then((wallets) {
      _walletsController.add(wallets);
    }).catchError((error) {
      if (!_walletsController.isClosed) {
        _walletsController.addError(error);
      }
    });

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final wallets = await _localDb.getWallets();
        if (!_walletsController.isClosed) {
          _walletsController.add(wallets);
        } else {
          timer.cancel();
        }
      } catch (error) {
        if (!_walletsController.isClosed) {
          _walletsController.addError(error);
        }
      }
    });

    return _walletsController.stream;
  }

  /// Add wallet
  Future<void> addWallet(Wallet wallet) async {
    await _syncService.syncWallet(wallet);
    final wallets = await _localDb.getWallets();
    _walletsController.add(wallets);
  }

  /// Update wallet
  Future<void> updateWallet(Wallet wallet) async {
    await _localDb.updateWallet(wallet, synced: false);
    if (FirebaseAuth.instance.currentUser != null) {
      await _syncService.syncWallet(wallet);
    }
    final wallets = await _localDb.getWallets();
    _walletsController.add(wallets);
  }

  /// Delete wallet
  Future<void> deleteWallet(String id) async {
    await _syncService.deleteWallet(id);
    final wallets = await _localDb.getWallets();
    _walletsController.add(wallets);
  }

  // ==========================================
  // BUDGETS
  // ==========================================

  /// Get budgets stream
  Stream<List<Budget>> getBudgets() {
    if (!_budgetsController.isClosed) {
      _budgetsController.add([]);
    }
    _localDb.getBudgets().then((budgets) {
      _budgetsController.add(budgets);
    }).catchError((error) {
      if (!_budgetsController.isClosed) {
        _budgetsController.addError(error);
      }
    });

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final budgets = await _localDb.getBudgets();
        if (!_budgetsController.isClosed) {
          _budgetsController.add(budgets);
        } else {
          timer.cancel();
        }
      } catch (error) {
        if (!_budgetsController.isClosed) {
          _budgetsController.addError(error);
        }
      }
    });

    return _budgetsController.stream;
  }

  /// Add budget
  Future<void> addBudget(Budget budget) async {
    await _syncService.syncBudget(budget);
    final budgets = await _localDb.getBudgets();
    _budgetsController.add(budgets);
  }

  /// Update budget
  Future<void> updateBudget(Budget budget) async {
    await _localDb.updateBudget(budget, synced: false);
    if (FirebaseAuth.instance.currentUser != null) {
      await _syncService.syncBudget(budget);
    }
    final budgets = await _localDb.getBudgets();
    _budgetsController.add(budgets);
  }

  /// Delete budget
  Future<void> deleteBudget(String id) async {
    await _syncService.deleteBudget(id);
    final budgets = await _localDb.getBudgets();
    _budgetsController.add(budgets);
  }

  // ==========================================
  // CALCULATION METHODS (from FirestoreService)
  // ==========================================

  Future<double> calculateWalletBalance(String walletId) async {
    return await _firestoreService.calculateWalletBalance(walletId);
  }

  Future<double> calculateTotalBalance() async {
    return await _firestoreService.calculateTotalBalance();
  }

  Future<double> calculateTotalIncome({Duration? period}) async {
    return await _firestoreService.calculateTotalIncome(period: period);
  }

  Future<double> calculateTotalExpenses({Duration? period}) async {
    return await _firestoreService.calculateTotalExpenses(period: period);
  }

  // ==========================================
  // SYNC METHODS
  // ==========================================

  /// Manually trigger a full sync
  Future<void> syncAll() async {
    await _syncService.syncAll();
    // Update all streams
    final transactions = await _localDb.getTransactions();
    final wallets = await _localDb.getWallets();
    final budgets = await _localDb.getBudgets();
    _transactionsController.add(transactions);
    _walletsController.add(wallets);
    _budgetsController.add(budgets);
  }

  /// Clear all local data (useful for logout)
  Future<void> clearLocalData() async {
    await _localDb.clearAllData();
    _transactionsController.add([]);
    _walletsController.add([]);
    _budgetsController.add([]);
  }
}
