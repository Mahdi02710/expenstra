import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_database_service.dart';
import 'firestore_service.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/budget.dart';

class SyncService {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final FirestoreService _firestoreService = FirestoreService();
  final Connectivity _connectivity = Connectivity();

  // Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Check if user is authenticated
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  // ==========================================
  // SYNC ALL DATA
  // ==========================================

  /// Syncs all data: first downloads from Firebase, then uploads local changes
  Future<void> syncAll() async {
    if (!isAuthenticated) return;

    final online = await isOnline();
    if (!online) {
      print('No internet connection. Using local data only.');
      return;
    }

    try {
      // Step 1: Download from Firebase and save to local DB
      await _downloadFromFirebase();

      // Step 2: Upload local changes to Firebase
      await _uploadToFirebase();
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  // ==========================================
  // DOWNLOAD FROM FIREBASE
  // ==========================================

  Future<void> _downloadFromFirebase() async {
    try {
      // Download transactions
      final transactions = await _firestoreService.getTransactions().first;
      for (final transaction in transactions) {
        await _localDb.insertTransaction(transaction, synced: true);
      }

      // Download wallets
      final wallets = await _firestoreService.getWallets().first;
      for (final wallet in wallets) {
        await _localDb.insertWallet(wallet, synced: true);
      }

      // Download budgets
      final budgets = await _firestoreService.getBudgets().first;
      for (final budget in budgets) {
        await _localDb.insertBudget(budget, synced: true);
      }

      print('Downloaded all data from Firebase');
    } catch (e) {
      print('Error downloading from Firebase: $e');
    }
  }

  // ==========================================
  // UPLOAD TO FIREBASE
  // ==========================================

  Future<void> _uploadToFirebase() async {
    try {
      // Upload unsynced transactions
      final unsyncedTransactions = await _localDb.getUnsyncedTransactions();
      for (final transaction in unsyncedTransactions) {
        try {
          await _firestoreService.addTransaction(transaction);
          await _localDb.markTransactionSynced(transaction.id);
        } catch (e) {
          print('Error uploading transaction ${transaction.id}: $e');
        }
      }

      // Upload unsynced wallets
      final wallets = await _localDb.getWallets();
      for (final wallet in wallets) {
        // Check if wallet exists in Firebase
        final firebaseWallets = await _firestoreService.getWallets().first;
        final exists = firebaseWallets.any((w) => w.id == wallet.id);

        try {
          if (exists) {
            await _firestoreService.updateWallet(wallet);
          } else {
            await _firestoreService.addWallet(wallet);
          }
          await _localDb.markWalletSynced(wallet.id);
        } catch (e) {
          print('Error uploading wallet ${wallet.id}: $e');
        }
      }

      // Upload unsynced budgets
      final budgets = await _localDb.getBudgets();
      for (final budget in budgets) {
        final firebaseBudgets = await _firestoreService.getBudgets().first;
        final exists = firebaseBudgets.any((b) => b.id == budget.id);

        try {
          if (exists) {
            await _firestoreService.updateBudget(budget);
          } else {
            await _firestoreService.addBudget(budget);
          }
          await _localDb.markBudgetSynced(budget.id);
        } catch (e) {
          print('Error uploading budget ${budget.id}: $e');
        }
      }

      print('Uploaded all local changes to Firebase');
    } catch (e) {
      print('Error uploading to Firebase: $e');
    }
  }

  // ==========================================
  // INDIVIDUAL SYNC METHODS
  // ==========================================

  /// Syncs a single transaction
  Future<void> syncTransaction(Transaction transaction) async {
    // Save to local DB first (always)
    await _localDb.insertTransaction(transaction, synced: false);

    // If online and authenticated, also save to Firebase
    if (isAuthenticated && await isOnline()) {
      try {
        await _firestoreService.addTransaction(transaction);
        await _localDb.markTransactionSynced(transaction.id);
      } catch (e) {
        print('Error syncing transaction to Firebase: $e');
        // Transaction remains in local DB with synced=false
      }
    }
  }

  /// Syncs a single wallet
  Future<void> syncWallet(Wallet wallet) async {
    await _localDb.insertWallet(wallet, synced: false);

    if (isAuthenticated && await isOnline()) {
      try {
        final wallets = await _firestoreService.getWallets().first;
        final exists = wallets.any((w) => w.id == wallet.id);

        if (exists) {
          await _firestoreService.updateWallet(wallet);
        } else {
          await _firestoreService.addWallet(wallet);
        }
        await _localDb.markWalletSynced(wallet.id);
      } catch (e) {
        print('Error syncing wallet to Firebase: $e');
      }
    }
  }

  /// Syncs a single budget
  Future<void> syncBudget(Budget budget) async {
    await _localDb.insertBudget(budget, synced: false);

    if (isAuthenticated && await isOnline()) {
      try {
        final budgets = await _firestoreService.getBudgets().first;
        final exists = budgets.any((b) => b.id == budget.id);

        if (exists) {
          await _firestoreService.updateBudget(budget);
        } else {
          await _firestoreService.addBudget(budget);
        }
        await _localDb.markBudgetSynced(budget.id);
      } catch (e) {
        print('Error syncing budget to Firebase: $e');
      }
    }
  }

  /// Deletes a transaction from both local and Firebase
  Future<void> deleteTransaction(String id) async {
    await _localDb.deleteTransaction(id, synced: false);

    if (isAuthenticated && await isOnline()) {
      try {
        await _firestoreService.deleteTransaction(id);
        await _localDb.markTransactionSynced(id);
      } catch (e) {
        print('Error deleting transaction from Firebase: $e');
      }
    }
  }

  /// Deletes a wallet from both local and Firebase
  Future<void> deleteWallet(String id) async {
    await _localDb.deleteWallet(id, synced: false);

    if (isAuthenticated && await isOnline()) {
      try {
        await _firestoreService.deleteWallet(id);
        await _localDb.markWalletSynced(id);
      } catch (e) {
        print('Error deleting wallet from Firebase: $e');
      }
    }
  }

  /// Deletes a budget from both local and Firebase
  Future<void> deleteBudget(String id) async {
    await _localDb.deleteBudget(id, synced: false);

    if (isAuthenticated && await isOnline()) {
      try {
        await _firestoreService.deleteBudget(id);
        await _localDb.markBudgetSynced(id);
      } catch (e) {
        print('Error deleting budget from Firebase: $e');
      }
    }
  }

  // ==========================================
  // STREAM METHODS (Read from local DB)
  // ==========================================

  /// Gets transactions stream from local DB, with periodic sync
  Stream<List<Transaction>> getTransactionsStream() async* {
    // Initial load from local DB
    final localTransactions =
        await _localDb.getTransactions() as List<Transaction>;
    yield localTransactions;

    // Periodically sync and update
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      if (isAuthenticated && await isOnline()) {
        await syncAll();
      }
      final updatedTransactions =
          await _localDb.getTransactions() as List<Transaction>;
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
