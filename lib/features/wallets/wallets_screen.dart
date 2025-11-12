import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/data_service.dart';
import 'widgets/wallets_overview.dart';
import 'widgets/wallet_grid.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen>
    with AutomaticKeepAliveClientMixin {
  final DataService _dataService = DataService();
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: WalletsOverview(
                    totalBalance: _dataService.getTotalBalance(),
                    totalDebt: _dataService.getTotalCreditDebt(),
                    walletCount: _dataService.wallets.length,
                  ),
                ),
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
              SliverToBoxAdapter(
                child: WalletGrid(
                  wallets: _dataService.wallets,
                  onWalletTap: _onWalletTap,
                ),
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
    final wallet = _dataService.getWallet(walletId);
    if (wallet == null) return const SizedBox();

    final transactions = _dataService.getTransactionsByWallet(walletId);

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
                      wallet.icon,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(wallet.name, style: AppTextStyles.h2),

                Text(wallet.typeLabel, style: AppTextStyles.body2),

                const SizedBox(height: 16),

                Text(
                  wallet.formattedBalanceWithSign,
                  style: AppTextStyles.currencyLarge.copyWith(
                    color: wallet.isCredit && wallet.balance < 0
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
                        _buildWalletDetailsTab(wallet),
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
  }

  Widget _buildWalletDetailsTab(wallet) {
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
    // Implement add wallet bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Add New Wallet', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            const Text('Wallet creation form would go here'),
            // Implement actual form
          ],
        ),
      ),
    );
  }

  void _showWalletOptionsMenu() {
    // Implement wallet options menu
  }

  void _showManageWalletsScreen() {
    // Navigate to manage wallets screen
  }
}
