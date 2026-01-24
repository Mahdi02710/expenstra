// ignore_for_file: avoid_print

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_database_service.dart';
import 'sync_service.dart';
import 'firestore_service.dart';
import 'settings_service.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/budget.dart';
import '../models/recurring_payment.dart';

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
  Timer? _transactionsTimer;
  Timer? _walletsTimer;
  Timer? _budgetsTimer;
  Timer? _recurringTimer;
  StreamSubscription<User?>? _authSub;
  bool _isRefreshingTransactions = false;
  bool _isRefreshingWallets = false;
  bool _isRefreshingBudgets = false;
  List<Transaction>? _lastTransactions;
  List<Wallet>? _lastWallets;
  List<Budget>? _lastBudgets;
  bool _isInitialized = false;

  /// Initialize the service - loads local data and starts syncing
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final autoSync = _settingsService.autoSyncEnabled.value;
      if (FirebaseAuth.instance.currentUser != null) {
        await _syncService.syncAll();
        await _refreshTransactions();
        await _refreshWallets();
        await _refreshBudgets();
        if (autoSync) {
          _startPeriodicSync();
        }
      }

      _authSub ??= FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user == null) {
          _syncTimer?.cancel();
          return;
        }
        await _syncService.syncAll();
        await _refreshTransactions();
        await _refreshWallets();
        await _refreshBudgets();
        if (_settingsService.autoSyncEnabled.value) {
          _startPeriodicSync();
        }
      });

      await _processMonthlyWalletRollover();
      await _processRecurringPayments();
      _startRecurringProcessing();

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

  void _startRecurringProcessing() {
    _recurringTimer?.cancel();
    _recurringTimer =
        Timer.periodic(const Duration(hours: 1), (_) => _processRecurringPayments());
  }

  void dispose() {
    _syncTimer?.cancel();
    _transactionsTimer?.cancel();
    _walletsTimer?.cancel();
    _budgetsTimer?.cancel();
    _recurringTimer?.cancel();
    _authSub?.cancel();
    _transactionsController.close();
    _walletsController.close();
    _budgetsController.close();
  }

  Future<void> _processMonthlyWalletRollover() async {
    final wallets = await _localDb.getWallets();
    if (wallets.isEmpty) return;

    final now = DateTime.now();
    // Only roll over at the start of a new month.
    if (now.day != 1) {
      return;
    }
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

  Future<void> _processRecurringPayments() async {
    final payments = await _localDb.getRecurringPayments();
    if (payments.isEmpty) return;

    final now = DateTime.now();
    for (final payment in payments) {
      if (!payment.isActive) {
        continue;
      }

      var nextRun = payment.nextRunAt;
      if (nextRun.isAfter(now)) {
        continue;
      }

      DateTime? lastRun;
      var guard = 0;
      while (!nextRun.isAfter(now) && guard < 36) {
        final tx = Transaction(
          id: (DateTime.now().microsecondsSinceEpoch + guard).toString(),
          type: payment.type,
          amount: payment.amount,
          description: payment.name,
          category: payment.category,
          icon: payment.icon,
          date: nextRun,
          walletId: payment.walletId,
          note: payment.note,
          currencyCode: _settingsService.defaultCurrency.value,
        );
        await addTransaction(tx);
        lastRun = nextRun;
        nextRun = payment.nextDate(nextRun);
        guard += 1;
      }

      final updated = payment.copyWith(
        lastRunAt: lastRun ?? payment.lastRunAt,
        nextRunAt: nextRun,
      );
      await _localDb.updateRecurringPayment(updated);
    }
  }

  Future<void> _refreshTransactions() async {
    if (_transactionsController.isClosed || _isRefreshingTransactions) {
      return;
    }
    _isRefreshingTransactions = true;
    try {
      final transactions = await _localDb.getTransactions();
      _lastTransactions = transactions;
      if (!_transactionsController.isClosed) {
        _transactionsController.add(transactions);
      }
    } catch (error) {
      if (!_transactionsController.isClosed) {
        _transactionsController.addError(error);
      }
    } finally {
      _isRefreshingTransactions = false;
    }
  }

  Future<void> _refreshWallets() async {
    if (_walletsController.isClosed || _isRefreshingWallets) {
      return;
    }
    _isRefreshingWallets = true;
    try {
      final wallets = await _localDb.getWallets();
      _lastWallets = wallets;
      if (!_walletsController.isClosed) {
        _walletsController.add(wallets);
      }
    } catch (error) {
      if (!_walletsController.isClosed) {
        _walletsController.addError(error);
      }
    } finally {
      _isRefreshingWallets = false;
    }
  }

  Future<void> _refreshBudgets() async {
    if (_budgetsController.isClosed || _isRefreshingBudgets) {
      return;
    }
    _isRefreshingBudgets = true;
    try {
      final budgets = await _localDb.getBudgets();
      _lastBudgets = budgets;
      if (!_budgetsController.isClosed) {
        _budgetsController.add(budgets);
      }
    } catch (error) {
      if (!_budgetsController.isClosed) {
        _budgetsController.addError(error);
      }
    } finally {
      _isRefreshingBudgets = false;
    }
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  /// Get transactions stream - reads from local DB, syncs in background
  Stream<List<Transaction>> getTransactions() {
    if (_lastTransactions != null && !_transactionsController.isClosed) {
      _transactionsController.add(_lastTransactions!);
    }
    _refreshTransactions();
    _transactionsTimer ??=
        Timer.periodic(const Duration(seconds: 8), (_) => _refreshTransactions());

    return _transactionsController.stream;
  }

  /// Add transaction - saves to local DB immediately, syncs to Firebase in background
  Future<void> addTransaction(Transaction transaction) async {
    await _syncService.syncTransaction(transaction);
    await _refreshTransactions();
  }

  /// Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await _localDb.updateTransaction(transaction, synced: false);
    if (FirebaseAuth.instance.currentUser != null) {
      await _syncService.syncTransaction(transaction);
    }
    await _refreshTransactions();
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    await _syncService.deleteTransaction(id);
    await _refreshTransactions();
  }

  // ==========================================
  // WALLETS
  // ==========================================

  /// Get wallets stream
  Stream<List<Wallet>> getWallets() {
    if (_lastWallets != null && !_walletsController.isClosed) {
      _walletsController.add(_lastWallets!);
    }
    _refreshWallets();
    _walletsTimer ??=
        Timer.periodic(const Duration(seconds: 8), (_) => _refreshWallets());

    return _walletsController.stream;
  }

  /// Add wallet
  Future<void> addWallet(Wallet wallet) async {
    await _syncService.syncWallet(wallet);
    await _refreshWallets();
  }

  /// Update wallet
  Future<void> updateWallet(Wallet wallet) async {
    await _localDb.updateWallet(wallet, synced: false);
    if (FirebaseAuth.instance.currentUser != null) {
      await _syncService.syncWallet(wallet);
    }
    await _refreshWallets();
  }

  /// Delete wallet
  Future<void> deleteWallet(String id) async {
    await _syncService.deleteWallet(id);
    await _refreshWallets();
  }

  // ==========================================
  // BUDGETS
  // ==========================================

  /// Get budgets stream
  Stream<List<Budget>> getBudgets() {
    if (_lastBudgets != null && !_budgetsController.isClosed) {
      _budgetsController.add(_lastBudgets!);
    }
    _refreshBudgets();
    _budgetsTimer ??=
        Timer.periodic(const Duration(seconds: 8), (_) => _refreshBudgets());

    return _budgetsController.stream;
  }

  /// Add budget
  Future<void> addBudget(Budget budget) async {
    await _syncService.syncBudget(budget);
    await _refreshBudgets();
  }

  /// Update budget
  Future<void> updateBudget(Budget budget) async {
    await _localDb.updateBudget(budget, synced: false);
    if (FirebaseAuth.instance.currentUser != null) {
      await _syncService.syncBudget(budget);
    }
    await _refreshBudgets();
  }

  /// Delete budget
  Future<void> deleteBudget(String id) async {
    await _syncService.deleteBudget(id);
    await _refreshBudgets();
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
    _lastTransactions = transactions;
    _lastWallets = wallets;
    _lastBudgets = budgets;
    _transactionsController.add(transactions);
    _walletsController.add(wallets);
    _budgetsController.add(budgets);
  }

  /// Clear all local data (useful for logout)
  Future<void> clearLocalData() async {
    await _localDb.clearAllData();
    _lastTransactions = const [];
    _lastWallets = const [];
    _lastBudgets = const [];
    _transactionsController.add([]);
    _walletsController.add([]);
    _budgetsController.add([]);
  }

  // ==========================================
  // RECURRING PAYMENTS
  // ==========================================

  Future<void> addRecurringPayment(RecurringPayment payment) async {
    await _localDb.insertRecurringPayment(payment);
    await _processRecurringPayments();
  }

  Future<void> updateRecurringPayment(RecurringPayment payment) async {
    await _localDb.updateRecurringPayment(payment);
  }

  Future<void> deleteRecurringPayment(String id) async {
    await _localDb.deleteRecurringPayment(id);
  }

  Future<List<RecurringPayment>> getRecurringPayments() async {
    return _localDb.getRecurringPayments();
  }
}
