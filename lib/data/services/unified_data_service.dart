import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_database_service.dart';
import 'sync_service.dart';
import 'firestore_service.dart';
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
      // Initial sync if user is authenticated
      if (FirebaseAuth.instance.currentUser != null) {
        await _syncService.syncAll();
      }

      // Start periodic syncing
      _startPeriodicSync();

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

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  /// Get transactions stream - reads from local DB, syncs in background
  Stream<List<Transaction>> getTransactions() {
    // Emit initial data from local DB
    _localDb.getTransactions().then((transactions) {
      if (!_transactionsController.isClosed) {
        _transactionsController.add(transactions);
      }
    });

    // Periodically update from local DB
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_transactionsController.isClosed) {
        timer.cancel();
        return;
      }
      final transactions = await _localDb.getTransactions();
      if (!_transactionsController.isClosed) {
        _transactionsController.add(transactions);
      } else {
        timer.cancel();
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
    _localDb.getWallets().then((wallets) {
      _walletsController.add(wallets);
    });

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      final wallets = await _localDb.getWallets();
      if (!_walletsController.isClosed) {
        _walletsController.add(wallets);
      } else {
        timer.cancel();
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
    _localDb.getBudgets().then((budgets) {
      _budgetsController.add(budgets);
    });

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      final budgets = await _localDb.getBudgets();
      if (!_budgetsController.isClosed) {
        _budgetsController.add(budgets);
      } else {
        timer.cancel();
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
