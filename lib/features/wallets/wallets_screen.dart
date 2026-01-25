// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/unified_data_service.dart';
import '../../data/models/wallet.dart';
import '../../data/models/transaction.dart';
import 'widgets/wallets_overview.dart';
import 'widgets/wallet_grid.dart';
import 'widgets/wallet_form.dart';
import '../../shared/utils/app_snackbar.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen>
    with AutomaticKeepAliveClientMixin {
  final UnifiedDataService _unifiedService = UnifiedDataService();
  final ScrollController _scrollController = ScrollController();
  WalletSortOption _sortOption = WalletSortOption.name;
  bool _sortAscending = true;
  Set<WalletType> _typeFilters = {};
  WalletStatusFilter _statusFilter = WalletStatusFilter.all;

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
                stream: _unifiedService.getWallets(),
                builder: (context, walletsSnapshot) {
                  return StreamBuilder<List<Transaction>>(
                    stream: _unifiedService.getTransactions(),
                    builder: (context, transactionsSnapshot) {
                      double totalBalance = 0.0;
                      double totalDebt = 0.0;
                      int walletCount = 0;

                      if (walletsSnapshot.hasData &&
                          transactionsSnapshot.hasData) {
                        final wallets = _applyWalletFilters(
                          walletsSnapshot.data!,
                        );
                        final transactions = transactionsSnapshot.data!;
                        walletCount = wallets.length;

                        // Calculate balances from transactions (starting from initial balance)
                        final Map<String, double> walletBalances = {};
                        for (final wallet in wallets) {
                          walletBalances[wallet.id] =
                              wallet.balance; // Start with initial balance
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
                          final balance =
                              walletBalances[wallet.id] ?? wallet.balance;
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
                stream: _unifiedService.getWallets(),
                builder: (context, walletsSnapshot) {
                  return StreamBuilder<List<Transaction>>(
                    stream: _unifiedService.getTransactions(),
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

                      if (walletsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      var wallets = _applyWalletFilters(
                        walletsSnapshot.data ?? [],
                      );
                      final transactions = transactionsSnapshot.data ?? [];

                      // Calculate balances for each wallet (initial balance + transactions)
                      final Map<String, double> walletBalances = {};
                      for (final wallet in wallets) {
                        walletBalances[wallet.id] =
                            wallet.balance; // Start with initial balance
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
                        final balance =
                            walletBalances[wallet.id] ?? wallet.balance;
                        return wallet.copyWith(balance: balance);
                      }).toList();

                      final sortedWallets = _sortWallets(
                        walletsWithBalances,
                        transactions,
                      );

                      return SliverToBoxAdapter(
                        child: WalletGrid(
                          wallets: sortedWallets,
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
      stream: _unifiedService.getWallets(),
      builder: (context, walletsSnapshot) {
        if (!walletsSnapshot.hasData) {
          return const SizedBox();
        }

        final wallet = walletsSnapshot.data!.firstWhere(
          (w) => w.id == walletId,
          orElse: () => walletsSnapshot.data!.first,
        );

        return StreamBuilder<List<Transaction>>(
          stream: _unifiedService.getTransactions(),
          builder: (context, transactionsSnapshot) {
            final transactions = (transactionsSnapshot.data ?? [])
                .where((tx) => tx.walletId == walletId)
                .toList();

            // Calculate balance from transactions (starting from initial balance)
            double balance = wallet.balance; // Start with initial balance
            balance += transactions.fold<double>(
              0.0,
              (sum, tx) =>
                  sum +
                  (tx.type == TransactionType.income ? tx.amount : -tx.amount),
            );

            final walletWithBalance = wallet.copyWith(balance: balance);

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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

                        Text(
                          walletWithBalance.typeLabel,
                          style: AppTextStyles.body2,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          walletWithBalance.formattedBalanceWithSign,
                          style: AppTextStyles.currencyLarge.copyWith(
                            color:
                                walletWithBalance.isCredit &&
                                    walletWithBalance.balance < 0
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
                            labelColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.gold
                                : AppColors.primary,
                            unselectedLabelColor: AppColors.textMuted,
                          ),

                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildWalletDetailsTab(
                                  walletWithBalance,
                                  hasTransactions: transactions.isNotEmpty,
                                ),
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

  Widget _buildWalletDetailsTab(
    Wallet wallet, {
    required bool hasTransactions,
  }) {
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
                  onPressed: () =>
                      _editWallet(wallet, bottomSheetContext: context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _deleteWallet(
                    wallet,
                    bottomSheetContext: context,
                    hasTransactions: hasTransactions,
                  ),
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
    ).then((result) async {
      if (result == null || result is! WalletFormResult) return;
      try {
        await _unifiedService.addWallet(result.wallet);
        await _applyRecurringPaymentChanges(result);
        if (mounted) {
<<<<<<< HEAD
          showAppSnackBar(
            context,
            'Wallet added successfully',
            backgroundColor: AppColors.success,
=======
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wallet added successfully'),
              backgroundColor: AppColors.success,
            ),
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
          );
        }
      } catch (error) {
        if (mounted) {
<<<<<<< HEAD
          showAppSnackBar(
            context,
            'Error: ${error.toString()}',
            backgroundColor: AppColors.error,
=======
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.toString()}'),
              backgroundColor: AppColors.error,
            ),
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
          );
        }
      }
    });
  }

  void _editWallet(Wallet wallet, {BuildContext? bottomSheetContext}) {
    if (bottomSheetContext != null) {
      final navigator = Navigator.of(bottomSheetContext);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WalletForm(wallet: wallet),
    ).then((result) async {
      if (result == null || result is! WalletFormResult) return;
      try {
        await _unifiedService.updateWallet(result.wallet);
        await _applyRecurringPaymentChanges(result);
        if (mounted) {
<<<<<<< HEAD
          showAppSnackBar(
            context,
            'Wallet updated successfully',
            backgroundColor: AppColors.success,
=======
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wallet updated successfully'),
              backgroundColor: AppColors.success,
            ),
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
          );
        }
      } catch (error) {
        if (mounted) {
<<<<<<< HEAD
          showAppSnackBar(
            context,
            'Error: ${error.toString()}',
            backgroundColor: AppColors.error,
=======
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.toString()}'),
              backgroundColor: AppColors.error,
            ),
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
          );
        }
      }
    });
  }

  Future<void> _applyRecurringPaymentChanges(
    WalletFormResult result,
  ) async {
    if (result.recurringPaymentIdToDelete != null) {
      await _unifiedService.deleteRecurringPayment(
        result.recurringPaymentIdToDelete!,
      );
    }
    if (result.recurringPayment != null) {
      if (result.recurringPaymentExists) {
        await _unifiedService.updateRecurringPayment(
          result.recurringPayment!,
        );
      } else {
        await _unifiedService.addRecurringPayment(result.recurringPayment!);
      }
    }
  }

  void _deleteWallet(
    Wallet wallet, {
    BuildContext? bottomSheetContext,
    bool hasTransactions = false,
  }) {
    if (hasTransactions) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Wallet has transactions'),
          content: const Text(
            'Please delete or move the wallet transactions before removing this wallet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: Text(
          'Are you sure you want to delete "${wallet.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (bottomSheetContext != null) {
                final navigator = Navigator.of(bottomSheetContext);
                if (navigator.canPop()) {
                  navigator.pop();
                }
              }

              try {
                await _unifiedService.deleteWallet(wallet.id);
                if (!mounted) return;
                showAppSnackBar(
                  context,
                  'Wallet deleted successfully',
                  backgroundColor: AppColors.success,
                );
              } catch (error) {
                if (!mounted) return;
                showAppSnackBar(
                  context,
                  'Error: ${error.toString()}',
                  backgroundColor: AppColors.error,
                );
              }
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
                Navigator.of(context).maybePop();
                _showAddWalletSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort Wallets'),
              onTap: () {
                Navigator.of(context).maybePop();
                _showSortSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Filter Wallets'),
              onTap: () {
                Navigator.of(context).maybePop();
                _showFilterSheet();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    var tempOption = _sortOption;
    var tempAscending = _sortAscending;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'Sort Wallets',
                      style: AppTextStyles.h3.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...WalletSortOption.values.map(
                      (option) => RadioListTile<WalletSortOption>(
                        title: Text(_sortLabel(option)),
                        value: option,
                        groupValue: tempOption,
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => tempOption = value);
                        },
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Ascending'),
                      value: tempAscending,
                      onChanged: (value) =>
                          setSheetState(() => tempAscending = value),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                tempOption = WalletSortOption.name;
                                tempAscending = true;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _sortOption = tempOption;
                                _sortAscending = tempAscending;
                              });
                              final navigator = Navigator.of(context);
                              if (navigator.canPop()) {
                                navigator.pop();
                              }
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    final tempTypes = Set<WalletType>.from(_typeFilters);
    var tempStatus = _statusFilter;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16, top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter Wallets',
                            style: AppTextStyles.h3.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Type', style: AppTextStyles.subtitle2),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: WalletType.values.map((type) {
                              final selected = tempTypes.contains(type);
                              return FilterChip(
                                label: Text(_typeLabel(type)),
                                selected: selected,
                                onSelected: (value) {
                                  setSheetState(() {
                                    if (value) {
                                      tempTypes.add(type);
                                    } else {
                                      tempTypes.remove(type);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text('Status', style: AppTextStyles.subtitle2),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: WalletStatusFilter.values.map((status) {
                              return ChoiceChip(
                                label: Text(_statusLabel(status)),
                                selected: tempStatus == status,
                                onSelected: (_) =>
                                    setSheetState(() => tempStatus = status),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      tempTypes.clear();
                                      tempStatus = WalletStatusFilter.all;
                                    });
                                  },
                                  child: const Text('Clear'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _typeFilters = tempTypes;
                                      _statusFilter = tempStatus;
                                    });
                                    final navigator = Navigator.of(context);
                                    if (navigator.canPop()) {
                                      navigator.pop();
                                    }
                                  },
                                  child: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: MediaQuery.of(context).padding.bottom),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Wallet> _applyWalletFilters(List<Wallet> wallets) {
    var filtered = wallets;
    if (_typeFilters.isNotEmpty) {
      filtered = filtered
          .where((wallet) => _typeFilters.contains(wallet.type))
          .toList();
    }
    switch (_statusFilter) {
      case WalletStatusFilter.active:
        filtered = filtered.where((wallet) => wallet.isActive).toList();
        break;
      case WalletStatusFilter.inactive:
        filtered = filtered.where((wallet) => !wallet.isActive).toList();
        break;
      case WalletStatusFilter.all:
        break;
    }
    return filtered;
  }

  List<Wallet> _sortWallets(
    List<Wallet> wallets,
    List<Transaction> transactions,
  ) {
    final sorted = [...wallets];
    int compare(Wallet a, Wallet b) {
      switch (_sortOption) {
        case WalletSortOption.balance:
          return a.balance.compareTo(b.balance);
        case WalletSortOption.type:
          return a.type.name.compareTo(b.type.name);
        case WalletSortOption.lastActivity:
          final aDate = _latestTransactionDate(transactions, a.id);
          final bDate = _latestTransactionDate(transactions, b.id);
          return (aDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            bDate ?? DateTime.fromMillisecondsSinceEpoch(0),
          );
        case WalletSortOption.name:
        // ignore: unreachable_switch_default
        default:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    }

    sorted.sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
    return sorted;
  }

  DateTime? _latestTransactionDate(List<Transaction> transactions, String id) {
    DateTime? latest;
    for (final tx in transactions) {
      if (tx.walletId != id) continue;
      if (latest == null || tx.date.isAfter(latest)) {
        latest = tx.date;
      }
    }
    return latest;
  }

  String _typeLabel(WalletType type) {
    switch (type) {
      case WalletType.bank:
        return 'Bank';
      case WalletType.savings:
        return 'Savings';
      case WalletType.credit:
        return 'Credit';
      case WalletType.cash:
        return 'Cash';
      case WalletType.investment:
        return 'Investment';
    }
  }

  String _statusLabel(WalletStatusFilter filter) {
    switch (filter) {
      case WalletStatusFilter.active:
        return 'Active';
      case WalletStatusFilter.inactive:
        return 'Inactive';
      case WalletStatusFilter.all:
        return 'All';
    }
  }

  String _sortLabel(WalletSortOption option) {
    switch (option) {
      case WalletSortOption.name:
        return 'Name';
      case WalletSortOption.balance:
        return 'Balance';
      case WalletSortOption.type:
        return 'Type';
      case WalletSortOption.lastActivity:
        return 'Last Activity';
    }
  }

  void _showManageWalletsScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Manage Wallets',
                    style: AppTextStyles.h3.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      final navigator = Navigator.of(sheetContext);
                      if (navigator.canPop()) {
                        navigator.pop();
                      }
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Wallet>>(
                  stream: _unifiedService.getWallets(),
                  builder: (context, walletsSnapshot) {
                    final wallets = walletsSnapshot.data ?? [];
                    return StreamBuilder<List<Transaction>>(
                      stream: _unifiedService.getTransactions(),
                      builder: (context, transactionsSnapshot) {
                        final transactions = transactionsSnapshot.data ?? [];
                        final txCountByWallet = <String, int>{};
                        for (final tx in transactions) {
                          txCountByWallet[tx.walletId] =
                              (txCountByWallet[tx.walletId] ?? 0) + 1;
                        }

                        if (wallets.isEmpty) {
                          return const Center(child: Text('No wallets found.'));
                        }

                        return ListView.separated(
                          itemCount: wallets.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final wallet = wallets[index];
                            final txCount = txCountByWallet[wallet.id] ?? 0;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Text(wallet.icon),
                              ),
                              title: Text(
                                wallet.name,
                                style: AppTextStyles.subtitle1.copyWith(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${wallet.typeLabel} · $txCount transactions',
                                style: AppTextStyles.caption,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: wallet.isActive,
                                    onChanged: (value) {
                                      _unifiedService.updateWallet(
                                        wallet.copyWith(isActive: value),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editWallet(
                                      wallet,
                                      bottomSheetContext: sheetContext,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteWallet(
                                      wallet,
                                      bottomSheetContext: sheetContext,
                                      hasTransactions: txCount > 0,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum WalletSortOption { name, balance, type, lastActivity }

enum WalletStatusFilter { all, active, inactive }
