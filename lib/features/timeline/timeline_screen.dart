import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/data_service.dart';
import '../../data/models/transaction.dart';
import 'widgets/balance_card.dart';
import 'widgets/transaction_list.dart';
import 'widgets/quick_actions.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
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

              // Balance Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BalanceCard(
                    totalBalance: _dataService.getTotalBalance(),
                    thisMonthIncome: _dataService.getTotalIncome(
                      period: const Duration(days: 30),
                    ),
                    thisMonthExpenses: _dataService.getTotalExpenses(
                      period: const Duration(days: 30),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Quick Actions
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

              // Section Header
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
                      TextButton(
                        onPressed: _showAllTransactions,
                        child: Text(
                          'View All',
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

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Transaction List
              SliverToBoxAdapter(
                child: TransactionList(
                  transactions: _dataService.transactions.take(10).toList(),
                  onTransactionTap: _onTransactionTap,
                ),
              ),

              // Bottom padding for navigation bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
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

  Future<void> _onRefresh() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real app, you would refresh data from the server here
    if (mounted) {
      setState(() {});
    }
  }

  void _onTransactionTap(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTransactionDetailSheet(transaction),
    );
  }

  Widget _buildTransactionDetailSheet(Transaction transaction) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Transaction header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryWithOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      transaction.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(transaction.description, style: AppTextStyles.h4),
                      Text(transaction.category, style: AppTextStyles.body2),
                    ],
                  ),
                ),

                Text(
                  transaction.formattedAmountWithSign,
                  style: AppTextStyles.getAmountStyle(
                    transaction.isIncome,
                    fontSize: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Transaction details
            _buildDetailRow('Date', transaction.formattedDate),
            _buildDetailRow('Time', transaction.formattedTime),
            if (transaction.note != null)
              _buildDetailRow('Note', transaction.note!),
            if (transaction.tags != null && transaction.tags!.isNotEmpty)
              _buildDetailRow('Tags', transaction.tags!.join(', ')),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editTransaction(transaction);
                    },
                    child: const Text('Edit'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteTransaction(transaction);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),

            // we already handle viewInsets via the scrollable padding above
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: AppTextStyles.body2)),
          Expanded(child: Text(value, style: AppTextStyles.body1)),
        ],
      ),
    );
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Search Transactions', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by description, category, or note...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // Implement search logic here
              },
            ),
            // Add search results here
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    // Implement filter bottom sheet
  }

  void _showAddTransactionSheet() {
    // Implement add transaction sheet
  }

  void _showAddIncomeSheet() {
    // Implement add income sheet
  }

  void _showAddExpenseSheet() {
    // Implement add expense sheet
  }

  void _showTransferSheet() {
    // Implement transfer sheet
  }

  void _showAllTransactions() {
    // Navigate to all transactions screen
  }

  void _editTransaction(Transaction transaction) {
    // Implement edit transaction
  }

  void _deleteTransaction(Transaction transaction) {
    // Implement delete transaction with confirmation
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
          ElevatedButton(
            onPressed: () {
              _dataService.removeTransaction(transaction.id);
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
