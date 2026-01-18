import 'dart:async';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/budget.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static Database? _database;
  static const String _dbName = 'expensetra.db';
  static const int _dbVersion = 3;

  // Table names
  static const String _transactionsTable = 'transactions';
  static const String _walletsTable = 'wallets';
  static const String _budgetsTable = 'budgets';
  static const String _syncTable = 'sync_queue';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE $_transactionsTable (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currencyCode TEXT DEFAULT 'USD',
        originalAmount REAL,
        exchangeRate REAL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        icon TEXT NOT NULL,
        date INTEGER NOT NULL,
        walletId TEXT NOT NULL,
        note TEXT,
        tags TEXT,
        synced INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Wallets table
    await db.execute('''
      CREATE TABLE $_walletsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        accountNumber TEXT,
        bankName TEXT,
        creditLimit REAL,
        isActive INTEGER DEFAULT 1,
        createdAt INTEGER NOT NULL,
        lastTransactionDate INTEGER,
        isMonthlyRollover INTEGER DEFAULT 0,
        rolloverToWalletId TEXT,
        lastRolloverAt INTEGER,
        synced INTEGER DEFAULT 0,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE $_budgetsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        spent REAL NOT NULL DEFAULT 0,
        `limit` REAL NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        period TEXT NOT NULL,
        category TEXT NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        isActive INTEGER DEFAULT 1,
        alertThreshold REAL,
        includedCategories TEXT,
        synced INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Sync queue table (for tracking items that need to be synced)
    await db.execute('''
      CREATE TABLE $_syncTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        recordId TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_transactions_date ON $_transactionsTable(date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_wallet ON $_transactionsTable(walletId)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_synced ON $_transactionsTable(synced)',
    );
    await db.execute(
      'CREATE INDEX idx_wallets_synced ON $_walletsTable(synced)',
    );
    await db.execute(
      'CREATE INDEX idx_budgets_synced ON $_budgetsTable(synced)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue ON $_syncTable(tableName, recordId)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here if needed
    if (oldVersion < newVersion) {
      if (oldVersion < 2) {
        await db.execute(
          'ALTER TABLE $_transactionsTable ADD COLUMN currencyCode TEXT DEFAULT "USD"',
        );
        await db.execute(
          'ALTER TABLE $_transactionsTable ADD COLUMN originalAmount REAL',
        );
        await db.execute(
          'ALTER TABLE $_transactionsTable ADD COLUMN exchangeRate REAL',
        );
      }
      if (oldVersion < 3) {
        await db.execute(
          'ALTER TABLE $_walletsTable ADD COLUMN isMonthlyRollover INTEGER DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE $_walletsTable ADD COLUMN rolloverToWalletId TEXT',
        );
        await db.execute(
          'ALTER TABLE $_walletsTable ADD COLUMN lastRolloverAt INTEGER',
        );
      }
    }
  }

  // TRANSACTIONS

  Future<void> insertTransaction(
    Transaction transaction, {
    bool synced = false,
  }) async {
    final db = await database;
    await db.insert(_transactionsTable, {
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
      'tags': transaction.tags?.join(','),
      'synced': synced ? 1 : 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (!synced) {
      await _addToSyncQueue(
        _transactionsTable,
        transaction.id,
        'insert',
        transaction.toMapForLocal(),
      );
    }
  }

  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _transactionsTable,
      orderBy: 'date DESC',
    );

    return List<Transaction>.generate(maps.length, (i) {
      return Transaction(
        id: maps[i]['id'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.name == maps[i]['type'] as String,
          orElse: () => TransactionType.expense,
        ),
        amount: (maps[i]['amount'] as num).toDouble(),
        currencyCode: maps[i]['currencyCode'] as String? ?? 'USD',
        originalAmount: maps[i]['originalAmount'] != null
            ? (maps[i]['originalAmount'] as num).toDouble()
            : null,
        exchangeRate: maps[i]['exchangeRate'] != null
            ? (maps[i]['exchangeRate'] as num).toDouble()
            : null,
        description: maps[i]['description'] as String,
        category: maps[i]['category'] as String,
        icon: maps[i]['icon'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(maps[i]['date'] as int),
        walletId: maps[i]['walletId'] as String,
        note: maps[i]['note'] as String?,
        tags: maps[i]['tags'] != null
            ? (maps[i]['tags'] as String)
                  .split(',')
                  .where((t) => t.isNotEmpty)
                  .toList()
            : null,
      );
    });
  }

  Future<void> updateTransaction(
    Transaction transaction, {
    bool synced = false,
  }) async {
    final db = await database;
    await db.update(
      _transactionsTable,
      {
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
        'tags': transaction.tags?.join(','),
        'synced': synced ? 1 : 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    if (!synced) {
      await _addToSyncQueue(
        _transactionsTable,
        transaction.id,
        'update',
        transaction.toMapForLocal(),
      );
    }
  }

  Future<void> deleteTransaction(String id, {bool synced = false}) async {
    final db = await database;
    await db.delete(_transactionsTable, where: 'id = ?', whereArgs: [id]);

    if (!synced) {
      await _addToSyncQueue(_transactionsTable, id, 'delete', null);
    }
  }

  Future<List<Transaction>> getUnsyncedTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _transactionsTable,
      where: 'synced = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromMap({
        'id': maps[i]['id'],
        'type': maps[i]['type'],
        'amount': maps[i]['amount'],
        'description': maps[i]['description'],
        'category': maps[i]['category'],
        'icon': maps[i]['icon'],
        'date': DateTime.fromMillisecondsSinceEpoch(maps[i]['date']),
        'walletId': maps[i]['walletId'],
        'note': maps[i]['note'],
        'tags': maps[i]['tags'],
      }, maps[i]['id']);
    });
  }

  Future<void> markTransactionSynced(String id) async {
    final db = await database;
    await db.update(
      _transactionsTable,
      {'synced': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // WALLETS

  Future<void> insertWallet(Wallet wallet, {bool synced = false}) async {
    final db = await database;
    await db.insert(_walletsTable, {
      'id': wallet.id,
      'name': wallet.name,
      'balance': wallet.balance,
      'type': wallet.type.toString(),
      'icon': wallet.icon,
      'color': wallet.color,
      'accountNumber': wallet.accountNumber,
      'bankName': wallet.bankName,
      'creditLimit': wallet.creditLimit,
      'isActive': wallet.isActive ? 1 : 0,
      'createdAt': wallet.createdAt.millisecondsSinceEpoch,
      'lastTransactionDate': wallet.lastTransactionDate?.millisecondsSinceEpoch,
      'isMonthlyRollover': wallet.isMonthlyRollover ? 1 : 0,
      'rolloverToWalletId': wallet.rolloverToWalletId,
      'lastRolloverAt': wallet.lastRolloverAt?.millisecondsSinceEpoch,
      'synced': synced ? 1 : 0,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (!synced) {
      await _addToSyncQueue(_walletsTable, wallet.id, 'insert', wallet.toMap());
    }
  }

  Future<List<Wallet>> getWallets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_walletsTable);

    return List<Wallet>.generate(maps.length, (i) {
      return Wallet.fromMap({
        'name': maps[i]['name'] as String,
        'balance': (maps[i]['balance'] as num).toDouble(),
        'type': maps[i]['type'] as String,
        'icon': maps[i]['icon'] as String,
        'color': maps[i]['color'] as String,
        'accountNumber': maps[i]['accountNumber'] as String?,
        'bankName': maps[i]['bankName'] as String?,
        'creditLimit': maps[i]['creditLimit'] != null
            ? (maps[i]['creditLimit'] as num).toDouble()
            : null,
        'isActive': (maps[i]['isActive'] as int) == 1,
        'createdAt': DateTime.fromMillisecondsSinceEpoch(
          maps[i]['createdAt'] as int,
        ),
        'lastTransactionDate': maps[i]['lastTransactionDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                maps[i]['lastTransactionDate'] as int,
              )
            : null,
        'isMonthlyRollover': (maps[i]['isMonthlyRollover'] as int?) == 1,
        'rolloverToWalletId': maps[i]['rolloverToWalletId'] as String?,
        'lastRolloverAt': maps[i]['lastRolloverAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                maps[i]['lastRolloverAt'] as int,
              )
            : null,
      }, maps[i]['id'] as String);
    });
  }

  Future<void> updateWallet(Wallet wallet, {bool synced = false}) async {
    final db = await database;
    await db.update(
      _walletsTable,
      {
        'name': wallet.name,
        'balance': wallet.balance,
        'type': wallet.type.toString(),
        'icon': wallet.icon,
        'color': wallet.color,
        'accountNumber': wallet.accountNumber,
        'bankName': wallet.bankName,
        'creditLimit': wallet.creditLimit,
        'isActive': wallet.isActive ? 1 : 0,
        'lastTransactionDate':
            wallet.lastTransactionDate?.millisecondsSinceEpoch,
        'isMonthlyRollover': wallet.isMonthlyRollover ? 1 : 0,
        'rolloverToWalletId': wallet.rolloverToWalletId,
        'lastRolloverAt': wallet.lastRolloverAt?.millisecondsSinceEpoch,
        'synced': synced ? 1 : 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [wallet.id],
    );

    if (!synced) {
      await _addToSyncQueue(_walletsTable, wallet.id, 'update', wallet.toMap());
    }
  }

  Future<double> calculateWalletBalance(String walletId) async {
    final db = await database;
    final walletRows = await db.query(
      _walletsTable,
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [walletId],
      limit: 1,
    );
    double balance = 0.0;
    if (walletRows.isNotEmpty) {
      balance = (walletRows.first['balance'] as num).toDouble();
    }

    final txRows = await db.query(
      _transactionsTable,
      columns: ['type', 'amount'],
      where: 'walletId = ?',
      whereArgs: [walletId],
    );
    for (final tx in txRows) {
      final type = tx['type'] as String;
      final amount = (tx['amount'] as num).toDouble();
      balance += type == 'income' ? amount : -amount;
    }
    return balance;
  }

  Future<void> deleteWallet(String id, {bool synced = false}) async {
    final db = await database;
    await db.delete(_walletsTable, where: 'id = ?', whereArgs: [id]);

    if (!synced) {
      await _addToSyncQueue(_walletsTable, id, 'delete', null);
    }
  }

  Future<void> markWalletSynced(String id) async {
    final db = await database;
    await db.update(
      _walletsTable,
      {'synced': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // BUDGETS
  // ==========================================

  Future<void> insertBudget(Budget budget, {bool synced = false}) async {
    final db = await database;
    await db.insert(_budgetsTable, {
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
      'isActive': budget.isActive ? 1 : 0,
      'alertThreshold': budget.alertThreshold,
      'includedCategories': budget.includedCategories?.join(','),
      'synced': synced ? 1 : 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (!synced) {
      await _addToSyncQueue(_budgetsTable, budget.id, 'insert', budget.toMap());
    }
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _budgetsTable,
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'startDate DESC',
    );

    return List<Budget>.generate(maps.length, (i) {
      return Budget.fromMap({
        'name': maps[i]['name'] as String,
        'spent': (maps[i]['spent'] as num).toDouble(),
        'limit': (maps[i]['limit'] as num).toDouble(),
        'icon': maps[i]['icon'] as String,
        'color': maps[i]['color'] as String,
        'period': maps[i]['period'] as String,
        'category': maps[i]['category'] as String,
        'startDate': DateTime.fromMillisecondsSinceEpoch(
          maps[i]['startDate'] as int,
        ),
        'endDate': DateTime.fromMillisecondsSinceEpoch(
          maps[i]['endDate'] as int,
        ),
        'isActive': (maps[i]['isActive'] as int) == 1,
        'alertThreshold': maps[i]['alertThreshold'] != null
            ? (maps[i]['alertThreshold'] as num).toDouble()
            : null,
        'includedCategories': maps[i]['includedCategories'] != null
            ? (maps[i]['includedCategories'] as String)
                  .split(',')
                  .where((c) => c.isNotEmpty)
                  .toList()
            : null,
      }, maps[i]['id'] as String);
    });
  }

  Future<void> updateBudget(Budget budget, {bool synced = false}) async {
    final db = await database;
    await db.update(
      _budgetsTable,
      {
        'name': budget.name,
        'spent': budget.spent,
        'limit': budget.limit,
        'icon': budget.icon,
        'color': budget.color,
        'period': budget.period.name,
        'category': budget.category,
        'startDate': budget.startDate.millisecondsSinceEpoch,
        'endDate': budget.endDate.millisecondsSinceEpoch,
        'isActive': budget.isActive ? 1 : 0,
        'alertThreshold': budget.alertThreshold,
        'includedCategories': budget.includedCategories?.join(','),
        'synced': synced ? 1 : 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [budget.id],
    );

    if (!synced) {
      await _addToSyncQueue(_budgetsTable, budget.id, 'update', budget.toMap());
    }
  }

  Future<void> deleteBudget(String id, {bool synced = false}) async {
    final db = await database;
    await db.delete(_budgetsTable, where: 'id = ?', whereArgs: [id]);

    if (!synced) {
      await _addToSyncQueue(_budgetsTable, id, 'delete', null);
    }
  }

  Future<void> markBudgetSynced(String id) async {
    final db = await database;
    await db.update(
      _budgetsTable,
      {'synced': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // SYNC QUEUE
  // ==========================================

  Future<void> _addToSyncQueue(
    String tableName,
    String recordId,
    String operation,
    Map<String, dynamic>? data,
  ) async {
    final db = await database;
    await db.insert(_syncTable, {
      'tableName': tableName,
      'recordId': recordId,
      'operation': operation,
      'data': data?.toString(), // Store as string for simplicity
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query(_syncTable, orderBy: 'createdAt ASC');
  }

  Future<void> removeFromSyncQueue(int syncId) async {
    final db = await database;
    await db.delete(_syncTable, where: 'id = ?', whereArgs: [syncId]);
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete(_syncTable);
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_transactionsTable);
    await db.delete(_walletsTable);
    await db.delete(_budgetsTable);
    await db.delete(_syncTable);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
