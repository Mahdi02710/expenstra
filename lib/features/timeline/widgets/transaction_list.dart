import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/transaction.dart';
import '../../../data/services/data_service.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(Transaction) onTransactionTap;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _buildEmptyState(context);
    }

    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};
    for (final transaction in transactions) {
      final dateLabel = transaction.dateLabel;
      groupedTransactions.putIfAbsent(dateLabel, () => []).add(transaction);
    }

    return Column(
      children: groupedTransactions.entries.map((entry) {
        final dateLabel = entry.key;
        final dayTransactions = entry.value;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateLabel,
                    style: AppTextStyles.subtitle1.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _getDayTotal(dayTransactions),
                    style: AppTextStyles.subtitle2.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Transactions for this date
            ...dayTransactions.map((transaction) => 
              TransactionItem(
                transaction: transaction,
                onTap: () => onTransactionTap(transaction),
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'No transactions yet',
            style: AppTextStyles.h4,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Your transactions will appear here once you start adding them.',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getDayTotal(List<Transaction> transactions) {
    final total = transactions.fold<double>(
      0.0,
      (sum, transaction) => sum + (transaction.isIncome ? transaction.amount : -transaction.amount),
    );
    
    final sign = total >= 0 ? '+' : '';
    return '$sign\$${total.abs().toStringAsFixed(2)}';
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    final wallet = dataService.getWallet(transaction.walletId ?? '');
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Transaction icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(context, transaction),
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
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: AppTextStyles.subtitle1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  Row(
                    children: [
                      Text(
                        transaction.category,
                        style: AppTextStyles.body2,
                      ),
                      
                      if (wallet != null) ...[
                        Text(
                          ' • ',
                          style: AppTextStyles.body2,
                        ),
                        Text(
                          wallet.name,
                          style: AppTextStyles.body2,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Amount and time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmountWithSign,
                  style: AppTextStyles.getAmountStyle(
                    transaction.isIncome,
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 2),
                
                Text(
                  transaction.timeAgo,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getIconBackgroundColor(BuildContext context, Transaction transaction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (transaction.isIncome) {
      return AppColors.income.withOpacity(0.15);
    } else {
      return (isDark ? AppColors.gold : AppColors.primary).withOpacity(0.1);
    }
  }
}