import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/data_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import 'widgets/balance_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/transaction_form.dart';
import 'widgets/transfer_form.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with AutomaticKeepAliveClientMixin {
  final DataService _dataService = DataService();
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();

  // Search and filter state
  String _searchQuery = '';
  TransactionType? _filterType;
  String? _filterCategory;
  String? _filterWalletId;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                'Timeline',
                style: AppTextStyles.h2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _showSearchBottomSheet,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterBottomSheet,
                ),
              ],
            ),

            StreamBuilder<List<Wallet>>(
              stream: _firestoreService.getWallets(),
              builder: (context, walletsSnapshot) {
                return StreamBuilder<List<Transaction>>(
                  stream: _firestoreService.getTransactions(),
                  builder: (context, transactionsSnapshot) {
                    double totalBalance = 0.0;
                    double thisMonthIncome = 0.0;
                    double thisMonthExpenses = 0.0;

                    if (walletsSnapshot.hasData && transactionsSnapshot.hasData) {
                      final wallets = walletsSnapshot.data!;
                      final transactions = transactionsSnapshot.data!;
                      final now = DateTime.now();
                      final thisMonthStart = DateTime(now.year, now.month);

                      // Calculate balances per wallet (initial balance + transactions)
                      final Map<String, double> walletBalances = {};
                      for (final wallet in wallets) {
                        walletBalances[wallet.id] = wallet.balance; // Start with initial balance
                      }

                      for (final tx in transactions) {
                        // Update wallet balance
                        walletBalances[tx.walletId] =
                            (walletBalances[tx.walletId] ?? 0.0) +
                                (tx.type == TransactionType.income
                                    ? tx.amount
                                    : -tx.amount);

                        // Calculate this month's income and expenses
                        if (tx.date.isAfter(thisMonthStart) ||
                            tx.date.isAtSameMomentAs(thisMonthStart)) {
                          if (tx.type == TransactionType.income) {
                            thisMonthIncome += tx.amount;
                          } else if (tx.type == TransactionType.expense) {
                            thisMonthExpenses += tx.amount;
                          }
                        }
                      }

                      // Calculate net worth from all wallets
                      // Net Worth = Assets (non-credit wallets) - Liabilities (credit card debt)
                      for (final wallet in wallets) {
                        final balance = walletBalances[wallet.id] ?? wallet.balance;
                        if (wallet.type == WalletType.credit) {
                          // Credit cards: only negative balances count as debt (liabilities)
                          // Positive balances (available credit) don't count as assets
                          if (balance < 0) {
                            totalBalance += balance; // Subtract debt (balance is negative)
                          }
                          // If balance >= 0, it's available credit, not an asset, so ignore it
                        } else {
                          // Non-credit wallets are assets
                          totalBalance += balance;
                        }
                      }
                    } else if (transactionsSnapshot.hasData) {
                      // Fallback: if wallets aren't loaded yet, just calculate from transactions
                      final transactions = transactionsSnapshot.data!;
                      final now = DateTime.now();
                      final thisMonthStart = DateTime(now.year, now.month);

                      for (final tx in transactions) {
                        if (tx.type == TransactionType.income) {
                          totalBalance += tx.amount;
                        } else if (tx.type == TransactionType.expense) {
                          totalBalance -= tx.amount;
                        }

                        if (tx.date.isAfter(thisMonthStart) ||
                            tx.date.isAtSameMomentAs(thisMonthStart)) {
                          if (tx.type == TransactionType.income) {
                            thisMonthIncome += tx.amount;
                          } else if (tx.type == TransactionType.expense) {
                            thisMonthExpenses += tx.amount;
                          }
                        }
                      }
                    }

                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: BalanceCard(
                          totalBalance: totalBalance,
                          thisMonthIncome: thisMonthIncome,
                          thisMonthExpenses: thisMonthExpenses,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuickActions(
                  onAddIncome: _showAddIncomeSheet,
                  onAddExpense: _showAddExpenseSheet,
                  onTransfer: _showTransferSheet,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: AppTextStyles.h3.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            StreamBuilder<List<Transaction>>(
              stream: FirestoreService().getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading transactions',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No transactions yet.\nTap + to add one!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var transactions = snapshot.data!;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  transactions = transactions.where((tx) {
                    final query = _searchQuery.toLowerCase();
                    return tx.description.toLowerCase().contains(query) ||
                        tx.category.toLowerCase().contains(query) ||
                        (tx.note?.toLowerCase().contains(query) ?? false);
                  }).toList();
                }

                // Apply type filter
                if (_filterType != null) {
                  transactions = transactions
                      .where((tx) => tx.type == _filterType)
                      .toList();
                }

                // Apply category filter
                if (_filterCategory != null) {
                  transactions = transactions
                      .where((tx) => tx.category == _filterCategory)
                      .toList();
                }

                // Apply wallet filter
                if (_filterWalletId != null) {
                  transactions = transactions
                      .where((tx) => tx.walletId == _filterWalletId)
                      .toList();
                }

                if (transactions.isEmpty &&
                    (_searchQuery.isNotEmpty ||
                        _filterType != null ||
                        _filterCategory != null ||
                        _filterWalletId != null)) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No transactions found.\nTry adjusting your filters.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tx = transactions[index];
                    return _buildTransactionItem(tx);
                  }, childCount: transactions.length),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.gold
            : AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Transaction'),
                content: Text(
                  'Are you sure you want to delete "${tx.description}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        _firestoreService
            .deleteTransaction(tx.id)
            .then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${tx.description}"'),
                    backgroundColor: AppColors.success,
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.white,
                      onPressed: () {
                        // Note: Undo would require re-adding the transaction
                        // This is a placeholder for future undo functionality
                      },
                    ),
                  ),
                );
              }
            })
            .catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error deleting transaction: ${error.toString()}',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => _onTransactionTap(tx),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(tx.icon, style: const TextStyle(fontSize: 20)),
            ),
            title: Text(
              tx.description,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${tx.category} • ${tx.dateLabel}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Text(
              tx.formattedAmountWithSign,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: tx.isIncome ? Colors.green : Colors.redAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionForm(),
    ).then((result) {
      if (result != null && result is Transaction) {
        _firestoreService
            .addTransaction(result)
            .then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${result.type == TransactionType.income ? "Income" : "Expense"} added successfully',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            })
            .catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${error.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            });
      }
    });
  }

  void _showAddIncomeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          const TransactionForm(initialType: TransactionType.income),
    ).then((result) {
      if (result != null && result is Transaction) {
        _firestoreService
            .addTransaction(result)
            .then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Income added successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            })
            .catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${error.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            });
      }
    });
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          const TransactionForm(initialType: TransactionType.expense),
    ).then((result) {
      if (result != null && result is Transaction) {
        _firestoreService
            .addTransaction(result)
            .then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense added successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            })
            .catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${error.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            });
      }
    });
  }

  void _showTransferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransferForm(),
    ).then((result) {
      if (result != null && result is Map) {
        final fromWalletId = result['fromWalletId'] as String;
        final toWalletId = result['toWalletId'] as String;
        final amount = result['amount'] as double;
        final note = result['note'] as String?;

        // Create two transactions: expense from source, income to destination
        final now = DateTime.now();
        final expenseTx = Transaction(
          id: '',
          type: TransactionType.expense,
          amount: amount,
          description:
              'Transfer to ${_dataService.getWallet(toWalletId)?.name ?? "Wallet"}',
          category: 'Transfer',
          icon: '↗️',
          date: now,
          walletId: fromWalletId,
          note: note,
        );

        final incomeTx = Transaction(
          id: '',
          type: TransactionType.income,
          amount: amount,
          description:
              'Transfer from ${_dataService.getWallet(fromWalletId)?.name ?? "Wallet"}',
          category: 'Transfer',
          icon: '↙️',
          date: now,
          walletId: toWalletId,
          note: note,
        );

        // Add both transactions
        Future.wait([
              _firestoreService.addTransaction(expenseTx),
              _firestoreService.addTransaction(incomeTx),
            ])
            .then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transfer completed successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            })
            .catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${error.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            });
      }
    });
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Search transactions',
                  hintText: 'Enter description, category, or note',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            Navigator.pop(context);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkInputBackground
                      : AppColors.inputBackground,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton(
                  onPressed: () {
                    setState(() => _searchQuery = '');
                    Navigator.pop(context);
                  },
                  child: const Text('Clear search'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter Transactions',
                    style: AppTextStyles.h3.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Type filter
                  Text('Type', style: AppTextStyles.subtitle2),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilterChip(
                          label: const Text('All'),
                          selected: _filterType == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _filterType = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilterChip(
                          label: const Text('Income'),
                          selected: _filterType == TransactionType.income,
                          onSelected: (selected) {
                            setState(() {
                              _filterType = selected
                                  ? TransactionType.income
                                  : null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilterChip(
                          label: const Text('Expense'),
                          selected: _filterType == TransactionType.expense,
                          onSelected: (selected) {
                            setState(() {
                              _filterType = selected
                                  ? TransactionType.expense
                                  : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Category filter
                  Text('Category', style: AppTextStyles.subtitle2),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterCategory == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterCategory = null);
                          }
                        },
                      ),
                      ...[
                        'Food & Drink',
                        'Transportation',
                        'Shopping',
                        'Housing',
                        'Entertainment',
                        'Health & Fitness',
                        'Income',
                        'Other',
                      ].map(
                        (category) => FilterChip(
                          label: Text(category),
                          selected: _filterCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _filterCategory = selected ? category : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Wallet filter
                  Text('Wallet', style: AppTextStyles.subtitle2),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterWalletId == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filterWalletId = null);
                          }
                        },
                      ),
                      ..._dataService.wallets.map(
                        (wallet) => FilterChip(
                          label: Text('${wallet.icon} ${wallet.name}'),
                          selected: _filterWalletId == wallet.id,
                          onSelected: (selected) {
                            setState(() {
                              _filterWalletId = selected ? wallet.id : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Clear filters button
                  if (_filterType != null ||
                      _filterCategory != null ||
                      _filterWalletId != null)
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _filterType = null;
                          _filterCategory = null;
                          _filterWalletId = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All Filters'),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTransactionTap(Transaction transaction) {
    final wallet = _dataService.getWallet(transaction.walletId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon and amount
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                (transaction.isIncome
                                        ? AppColors.income
                                        : AppColors.expense)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            transaction.icon,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          transaction.formattedAmountWithSign,
                          style: AppTextStyles.currencyLarge.copyWith(
                            color: transaction.isIncome
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          transaction.description,
                          style: AppTextStyles.h4.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Details
                  _buildDetailRow('Category', transaction.category),
                  _buildDetailRow('Date', transaction.formattedDate),
                  _buildDetailRow('Time', transaction.formattedTime),
                  if (wallet != null)
                    _buildDetailRow('Wallet', '${wallet.icon} ${wallet.name}'),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    _buildDetailRow('Note', transaction.note!),

                  const SizedBox(height: 24),

                  // Delete button
                  ElevatedButton(
                    onPressed: () {
                      _deleteTransactionFromDetails(transaction, context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Delete Transaction'),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _firestoreService
                  .deleteTransaction(transaction.id)
                  .then((_) {
                    if (mounted) {
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction deleted'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  })
                  .catchError((error) {
                    if (mounted) {
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${error.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  });
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteTransactionFromDetails(
    Transaction transaction,
    BuildContext bottomSheetContext,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${transaction.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _firestoreService
                  .deleteTransaction(transaction.id)
                  .then((_) {
                    if (mounted) {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(bottomSheetContext); // Close bottom sheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction deleted'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  })
                  .catchError((error) {
                    if (mounted) {
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${error.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  });
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
