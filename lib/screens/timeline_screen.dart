import 'package:flutter/material.dart';
import '../data/services/data_service.dart';
import '../data/models/transaction.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    final transactions = dataService.transactions;

    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};
    for (final transaction in transactions) {
      final dateKey = transaction.dateLabel;
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00033a),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFd2ab17).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFFd2ab17).withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'This Month',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFd2ab17),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF163473),
                    Color(0xFF162647),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$${dataService.getTotalBalance().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Income: \$${dataService.getTotalIncome().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        'Expenses: \$${dataService.getTotalExpenses().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transactions by date
            ...groupedTransactions.entries.map((entry) {
              final date = entry.key;
              final dayTransactions = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      date.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6b7280),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...dayTransactions.map((transaction) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TransactionCard(transaction: transaction),
                  )),
                  const SizedBox(height: 16),
                ],
              );
            }),
            const SizedBox(height: 80), // Bottom navigation space
          ],
        ),
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? Colors.green[600] : Colors.red[600];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFF162647).withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isIncome 
                ? Colors.green[100] 
                : Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transaction.icon,
              style: TextStyle(
                fontSize: 16,
                color: amountColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Description and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00033a),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.category} • ${transaction.timeAgo}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ),

          // Amount and arrow
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                transaction.formattedAmountWithSign,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isIncome ? Icons.call_received : Icons.call_made,
                size: 16,
                color: amountColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
