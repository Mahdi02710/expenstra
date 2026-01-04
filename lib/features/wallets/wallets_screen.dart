import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/wallet.dart';
import '../../data/models/transaction.dart';
import 'widgets/wallets_overview.dart';
import 'widgets/wallet_grid.dart';
import 'widgets/wallet_form.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen>
    with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();

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
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                title: Text(
                  'Wallets',
                  style: AppTextStyles.h2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddWalletSheet,
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: _showWalletOptionsMenu,
                  ),
                ],
              ),

              // Wallets Overview
              StreamBuilder<List<Wallet>>(
                stream: _firestoreService.getWallets(),
                builder: (context, walletsSnapshot) {
                  return StreamBuilder<List<Transaction>>(
                    stream: _firestoreService.getTransactions(),
                    builder: (context, transactionsSnapshot) {
                      double totalBalance = 0.0;
                      double totalDebt = 0.0;
                      int walletCount = 0;

                      if (walletsSnapshot.hasData && transactionsSnapshot.hasData) {
                        final wallets = walletsSnapshot.data!;
                        final transactions = transactionsSnapshot.data!;
                        walletCount = wallets.length;

                        // Calculate balances from transactions (starting from initial balance)
                        final Map<String, double> walletBalances = {};
                        for (final wallet in wallets) {
                          walletBalances[wallet.id] = wallet.balance; // Start with initial balance
                        }
                        for (final tx in transactions) {
                          walletBalances[tx.walletId] =
                              (walletBalances[tx.walletId] ?? 0.0) +
                                  (tx.type == TransactionType.income
                                      ? tx.amount
                                      : -tx.amount);
                        }

                        // Calculate totals for net worth
                        // Assets = non-credit wallet balances
                        // Liabilities = credit card debts (negative balances only)
                        for (final wallet in wallets) {
                          final balance = walletBalances[wallet.id] ?? wallet.balance;
                          if (wallet.type == WalletType.credit) {
                            // Credit cards: only negative balances are debt
                            // Positive balances (available credit) don't count as assets
                            if (balance < 0) {
                              totalDebt += balance.abs();
                            }
                          } else {
                            // Non-credit wallets are assets
                            totalBalance += balance;
                          }
                        }
                      }

                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: WalletsOverview(
                            totalBalance: totalBalance,
                            totalDebt: totalDebt,
                            walletCount: walletCount,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Wallets',
                        style: AppTextStyles.h3.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: _showManageWalletsScreen,
                        child: Text(
                          'Manage',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.gold
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Wallet Grid
              StreamBuilder<List<Wallet>>(
                stream: _firestoreService.getWallets(),
                builder: (context, walletsSnapshot) {
                  return StreamBuilder<List<Transaction>>(
                    stream: _firestoreService.getTransactions(),
                    builder: (context, transactionsSnapshot) {
                      if (walletsSnapshot.hasError) {
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
                                    'Error loading wallets',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      if (walletsSnapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      final wallets = walletsSnapshot.data ?? [];
                      final transactions = transactionsSnapshot.data ?? [];

                      // Calculate balances for each wallet (initial balance + transactions)
                      final Map<String, double> walletBalances = {};
                      for (final wallet in wallets) {
                        walletBalances[wallet.id] = wallet.balance; // Start with initial balance
                      }
                      for (final tx in transactions) {
                        walletBalances[tx.walletId] =
                            (walletBalances[tx.walletId] ?? 0.0) +
                                (tx.type == TransactionType.income
                                    ? tx.amount
                                    : -tx.amount);
                      }

                      // Create wallets with updated balances
                      final walletsWithBalances = wallets.map((wallet) {
                        final balance = walletBalances[wallet.id] ?? wallet.balance;
                        return wallet.copyWith(balance: balance);
                      }).toList();

                      return SliverToBoxAdapter(
                        child: WalletGrid(
                          wallets: walletsWithBalances,
                          onWalletTap: _onWalletTap,
                        ),
                      );
                    },
                  );
                },
              ),

              // Quick Actions Section
              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Quick Actions',
                    style: AppTextStyles.h3.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Quick Actions Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickActionsGrid(),
                ),
              ),

              // Bottom padding for navigation bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWalletSheet,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.gold
            : AppColors.primary,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.navy
            : Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'icon': Icons.account_balance,
        'label': 'Add Bank Account',
        'color': AppColors.primary,
        'onTap': () => _showAddWalletSheet(type: 'bank'),
      },
      {
        'icon': Icons.credit_card,
        'label': 'Add Credit Card',
        'color': AppColors.expense,
        'onTap': () => _showAddWalletSheet(type: 'credit'),
      },
      {
        'icon': Icons.savings,
        'label': 'Add Savings',
        'color': AppColors.income,
        'onTap': () => _showAddWalletSheet(type: 'savings'),
      },
      {
        'icon': Icons.attach_money,
        'label': 'Add Cash',
        'color': AppColors.gold,
        'onTap': () => _showAddWalletSheet(type: 'cash'),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),

      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          onTap: action['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                label,
                style: AppTextStyles.subtitle2.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {});
    }
  }

  void _onWalletTap(String walletId) {
    // Navigate to wallet details screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWalletDetailSheet(walletId),
    );
  }

  Widget _buildWalletDetailSheet(String walletId) {
    return StreamBuilder<List<Wallet>>(
      stream: _firestoreService.getWallets(),
      builder: (context, walletsSnapshot) {
        if (!walletsSnapshot.hasData) {
          return const SizedBox();
        }

        final wallet = walletsSnapshot.data!
            .firstWhere((w) => w.id == walletId, orElse: () => walletsSnapshot.data!.first);
        
        return StreamBuilder<List<Transaction>>(
          stream: _firestoreService.getTransactions(),
          builder: (context, transactionsSnapshot) {
            final transactions = (transactionsSnapshot.data ?? [])
                .where((tx) => tx.walletId == walletId)
                .toList();

            // Calculate balance from transactions (starting from initial balance)
            double balance = wallet.balance; // Start with initial balance
            balance += transactions.fold<double>(
              0.0,
              (sum, tx) => sum +
                  (tx.type == TransactionType.income ? tx.amount : -tx.amount),
            );

            final walletWithBalance = wallet.copyWith(balance: balance);

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Wallet header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              walletWithBalance.icon,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(walletWithBalance.name, style: AppTextStyles.h2),

                        Text(walletWithBalance.typeLabel, style: AppTextStyles.body2),

                        const SizedBox(height: 16),

                        Text(
                          walletWithBalance.formattedBalanceWithSign,
                          style: AppTextStyles.currencyLarge.copyWith(
                            color: walletWithBalance.isCredit && walletWithBalance.balance < 0
                                ? AppColors.expense
                                : AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Wallet details and transactions
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          TabBar(
                            tabs: const [
                              Tab(text: 'Details'),
                              Tab(text: 'Transactions'),
                            ],
                            labelColor: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.gold
                                : AppColors.primary,
                            unselectedLabelColor: AppColors.textMuted,
                          ),

                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildWalletDetailsTab(walletWithBalance),
                                _buildWalletTransactionsTab(transactions),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWalletDetailsTab(Wallet wallet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Account Number', wallet.maskedAccountNumber),
          _buildDetailRow('Bank', wallet.bankName ?? 'N/A'),
          _buildDetailRow('Type', wallet.typeLabel),
          _buildDetailRow('Status', wallet.isActive ? 'Active' : 'Inactive'),
          if (wallet.isCredit && wallet.creditLimit != null) ...[
            _buildDetailRow(
              'Credit Limit',
              '\$${wallet.creditLimit!.toStringAsFixed(2)}',
            ),
            _buildDetailRow('Utilization', wallet.creditUtilizationPercentage),
          ],
          _buildDetailRow('Last Activity', wallet.lastActivityText),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editWallet(wallet),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _deleteWallet(wallet),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTransactionsTab(List<dynamic> transactions) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions in this wallet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return ListTile(
          leading: CircleAvatar(child: Text(transaction.icon)),
          title: Text(transaction.description),
          subtitle: Text(transaction.category),
          trailing: Text(
            transaction.formattedAmountWithSign,
            style: AppTextStyles.getAmountStyle(transaction.isIncome),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTextStyles.body2)),
          Expanded(child: Text(value, style: AppTextStyles.body1)),
        ],
      ),
    );
  }

  void _showAddWalletSheet({String? type}) {
    WalletType? walletType;
    if (type != null) {
      switch (type) {
        case 'bank':
          walletType = WalletType.bank;
          break;
        case 'credit':
          walletType = WalletType.credit;
          break;
        case 'savings':
          walletType = WalletType.savings;
          break;
        case 'cash':
          walletType = WalletType.cash;
          break;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WalletForm(initialType: walletType),
    ).then((result) {
      if (result != null && result is Wallet) {
        _firestoreService
            .addWallet(result)
            .then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wallet added successfully'),
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

  void _editWallet(Wallet wallet) {
    Navigator.pop(context); // Close detail sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WalletForm(wallet: wallet),
    ).then((result) {
      if (result != null && result is Wallet) {
        _firestoreService
            .updateWallet(result)
            .then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wallet updated successfully'),
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

  void _deleteWallet(Wallet wallet) {
    Navigator.pop(context); // Close detail sheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: Text(
          'Are you sure you want to delete "${wallet.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _firestoreService
                  .deleteWallet(wallet.id)
                  .then((_) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Wallet deleted successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  })
                  .catchError((error) {
                    if (mounted) {
                      Navigator.pop(context);
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

  void _showWalletOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Wallet'),
              onTap: () {
                Navigator.pop(context);
                _showAddWalletSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort Wallets'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement sorting
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Filter Wallets'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement filtering
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showManageWalletsScreen() {
    // Show manage wallets dialog or navigate to screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Wallets'),
        content: const Text('Wallet management features coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
