import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/budget.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal() {
    _initializeSampleData();
  }

  final List<Transaction> _transactions = [];
  final List<Wallet> _wallets = [];
  final List<Budget> _budgets = [];

  // Getters
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Wallet> get wallets => List.unmodifiable(_wallets);
  List<Budget> get budgets => List.unmodifiable(_budgets);

  void _initializeSampleData() {
    // Clear existing data
    _transactions.clear();
    _wallets.clear();
    _budgets.clear();

    // Sample Wallets
    _wallets.addAll([
      Wallet(
        id: '1',
        name: 'Chase Checking',
        balance: 8247.32,
        type: WalletType.bank,
        icon: '🏦',
        color: 'blue',
        accountNumber: '1234',
        bankName: 'Chase Bank',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        lastTransactionDate: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Wallet(
        id: '2',
        name: 'Savings Account',
        balance: 12544.50,
        type: WalletType.savings,
        icon: '💰',
        color: 'green',
        accountNumber: '5678',
        bankName: 'Wells Fargo',
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Wallet(
        id: '3',
        name: 'Credit Card',
        balance: -2200.00,
        type: WalletType.credit,
        icon: '💳',
        color: 'red',
        accountNumber: '9012',
        bankName: 'Capital One',
        creditLimit: 5000.00,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        lastTransactionDate: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Wallet(
        id: '4',
        name: 'Cash Wallet',
        balance: 245.00,
        type: WalletType.cash,
        icon: '💵',
        color: 'yellow',
        accountNumber: 'CASH',
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        lastTransactionDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // Sample Transactions
    final now = DateTime.now();
    _transactions.addAll([
      Transaction(
        id: '1',
        type: TransactionType.expense,
        amount: 4.50,
        description: 'Morning Coffee',
        category: 'Food & Drink',
        icon: '☕',
        date: now.subtract(const Duration(hours: 2)),
        walletId: '1',
        note: 'Starbucks downtown',
        tags: ['coffee', 'morning'],
      ),
      Transaction(
        id: '2',
        type: TransactionType.expense,
        amount: 25.00,
        description: 'Gas Station',
        category: 'Transportation',
        icon: '⛽',
        date: now.subtract(const Duration(hours: 4)),
        walletId: '1',
        note: 'Shell gas station',
      ),
      Transaction(
        id: '3',
        type: TransactionType.income,
        amount: 150.00,
        description: 'Freelance Payment',
        category: 'Income',
        icon: '💼',
        date: now.subtract(const Duration(hours: 6)),
        walletId: '1',
        note: 'Web development project',
        tags: ['freelance', 'income'],
      ),
      Transaction(
        id: '4',
        type: TransactionType.expense,
        amount: 89.99,
        description: 'Online Shopping',
        category: 'Shopping',
        icon: '🛍️',
        date: now.subtract(const Duration(days: 1)),
        walletId: '3',
        note: 'Amazon purchase',
        tags: ['amazon', 'electronics'],
      ),
      Transaction(
        id: '5',
        type: TransactionType.expense,
        amount: 1200.00,
        description: 'Monthly Rent',
        category: 'Housing',
        icon: '🏠',
        date: now.subtract(const Duration(days: 2)),
        walletId: '1',
        note: 'Apartment rent payment',
        tags: ['rent', 'housing'],
      ),
      Transaction(
        id: '6',
        type: TransactionType.expense,
        amount: 45.67,
        description: 'Grocery Shopping',
        category: 'Food & Drink',
        icon: '🛒',
        date: now.subtract(const Duration(days: 3)),
        walletId: '1',
        note: 'Weekly groceries',
        tags: ['groceries', 'food'],
      ),
      Transaction(
        id: '7',
        type: TransactionType.income,
        amount: 2500.00,
        description: 'Monthly Salary',
        category: 'Income',
        icon: '💰',
        date: now.subtract(const Duration(days: 5)),
        walletId: '1',
        note: 'Regular salary payment',
        tags: ['salary', 'income'],
      ),
      Transaction(
        id: '8',
        type: TransactionType.expense,
        amount: 12.50,
        description: 'Movie Ticket',
        category: 'Entertainment',
        icon: '🎬',
        date: now.subtract(const Duration(days: 7)),
        walletId: '4',
        note: 'Weekend movie',
        tags: ['entertainment', 'movies'],
      ),
      Transaction(
        id: '9',
        type: TransactionType.expense,
        amount: 78.90,
        description: 'Utility Bills',
        category: 'Bills & Utilities',
        icon: '⚡',
        date: now.subtract(const Duration(days: 10)),
        walletId: '1',
        note: 'Electricity bill',
        tags: ['utilities', 'bills'],
      ),
      Transaction(
        id: '10',
        type: TransactionType.expense,
        amount: 35.00,
        description: 'Gym Membership',
        category: 'Health & Fitness',
        icon: '🏋️',
        date: now.subtract(const Duration(days: 15)),
        walletId: '1',
        note: 'Monthly gym fee',
        tags: ['fitness', 'health'],
      ),
    ]);

    // Sample Budgets
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    
    _budgets.addAll([
      Budget(
        id: '1',
        name: 'Food & Dining',
        spent: 324.50,
        limit: 500.00,
        icon: '🍽️',
        color: 'blue',
        period: BudgetPeriod.monthly,
        category: 'Food & Drink',
        startDate: currentMonth,
        endDate: nextMonth,
        alertThreshold: 0.8,
        includedCategories: ['Food & Drink'],
      ),
      Budget(
        id: '2',
        name: 'Transportation',
        spent: 180.75,
        limit: 300.00,
        icon: '🚗',
        color: 'green',
        period: BudgetPeriod.monthly,
        category: 'Transportation',
        startDate: currentMonth,
        endDate: nextMonth,
        alertThreshold: 0.75,
        includedCategories: ['Transportation'],
      ),
      Budget(
        id: '3',
        name: 'Shopping',
        spent: 450.00,
        limit: 400.00,
        icon: '🛍️',
        color: 'red',
        period: BudgetPeriod.monthly,
        category: 'Shopping',
        startDate: currentMonth,
        endDate: nextMonth,
        alertThreshold: 0.9,
        includedCategories: ['Shopping'],
      ),
      Budget(
        id: '4',
        name: 'Entertainment',
        spent: 89.99,
        limit: 200.00,
        icon: '🎬',
        color: 'purple',
        period: BudgetPeriod.monthly,
        category: 'Entertainment',
        startDate: currentMonth,
        endDate: nextMonth,
        alertThreshold: 0.8,
        includedCategories: ['Entertainment'],
      ),
    ]);

    // Sort transactions by date (newest first)
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  // Transaction methods
  List<Transaction> getTransactionsThisMonth() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    return _transactions.where((t) => 
      t.date.isAfter(thisMonth) || t.date.isAtSameMomentAs(thisMonth)
    ).toList();
  }

  List<Transaction> getTransactionsThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _transactions.where((t) => t.date.isAfter(weekStartDate)).toList();
  }

  List<Transaction> getTransactionsByWallet(String walletId) {
    return _transactions.where((t) => t.walletId == walletId).toList();
  }

  List<Transaction> getTransactionsByCategory(String category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  double getTotalIncome({Duration? period}) {
    var transactions = _transactions;
    if (period != null) {
      final cutoff = DateTime.now().subtract(period);
      transactions = _transactions.where((t) => t.date.isAfter(cutoff)).toList();
    }
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenses({Duration? period}) {
    var transactions = _transactions;
    if (period != null) {
      final cutoff = DateTime.now().subtract(period);
      transactions = _transactions.where((t) => t.date.isAfter(cutoff)).toList();
    }
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalBalance() {
    return _wallets
        .where((w) => w.type != WalletType.credit)
        .fold(0.0, (sum, wallet) => sum + wallet.balance);
  }

  double getTotalCreditDebt() {
    return _wallets
        .where((w) => w.type == WalletType.credit && w.balance < 0)
        .fold(0.0, (sum, wallet) => sum + wallet.balance.abs());
  }

  Map<String, double> getSpendingByCategory({Duration? period}) {
    var transactions = _transactions;
    if (period != null) {
      final cutoff = DateTime.now().subtract(period);
      transactions = _transactions.where((t) => t.date.isAfter(cutoff)).toList();
    }

    final categorySpending = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        categorySpending[transaction.category] = 
            (categorySpending[transaction.category] ?? 0.0) + transaction.amount;
      }
    }
    return categorySpending;
  }

  // CRUD operations
  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  void updateTransaction(Transaction transaction) {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  void removeTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
  }

  void addWallet(Wallet wallet) {
    _wallets.add(wallet);
  }

  void updateWallet(Wallet wallet) {
    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index != -1) {
      _wallets[index] = wallet;
    }
  }

  void removeWallet(String id) {
    _wallets.removeWhere((w) => w.id == id);
  }

  void addBudget(Budget budget) {
    _budgets.add(budget);
  }

  void updateBudget(Budget budget) {
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _budgets[index] = budget;
    }
  }

  void removeBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
  }

  // Helper methods
  Wallet? getWallet(String id) {
    try {
      return _wallets.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  Budget? getBudget(String id) {
    try {
      return _budgets.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  Transaction? getTransaction(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> getAllCategories() {
    final categories = <String>{};
    for (final transaction in _transactions) {
      categories.add(transaction.category);
    }
    return categories.toList()..sort();
  }

  List<Transaction> searchTransactions(String query) {
    final lowerQuery = query.toLowerCase();
    return _transactions.where((t) => 
      t.description.toLowerCase().contains(lowerQuery) ||
      t.category.toLowerCase().contains(lowerQuery) ||
      (t.note?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }
}