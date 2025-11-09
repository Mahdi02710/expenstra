import 'package:flutter/material.dart';
import '../data/services/data_service.dart';
import '../data/models/budget.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    final budgets = dataService.budgets;
    final totalSpent = budgets.fold(0.0, (sum, budget) => sum + budget.spent);
    final totalLimit = budgets.fold(0.0, (sum, budget) => sum + budget.limit);

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
                  'Budgets',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00033a),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddBudgetDialog(context);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Budget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd2ab17),
                    foregroundColor: const Color(0xFF00033a),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Overview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF163473).withOpacity(0.1),
                    const Color(0xFF162647).withOpacity(0.1),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border.all(
                  color: const Color(0xFF163473).withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'This Month',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
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
                        child: Text(
                          '${budgets.length} Budgets',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFd2ab17),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Spent: \$${totalSpent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00033a),
                            ),
                          ),
                          Text(
                            'Budget: \$${totalLimit.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: totalSpent / totalLimit,
                        backgroundColor: const Color(
                          0xFF6b7280,
                        ).withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          totalSpent > totalLimit
                              ? Colors.red[600]!
                              : const Color(0xFF163473),
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${((totalSpent / totalLimit) * 100).toStringAsFixed(1)}% of total budget used',
                        style: TextStyle(
                          fontSize: 14,
                          color: totalSpent > totalLimit
                              ? Colors.red[600]
                              : const Color(0xFF6b7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Budget List
            const Text(
              'Your Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00033a),
              ),
            ),
            const SizedBox(height: 12),

            ...budgets.map(
              (budget) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BudgetCard(budget: budget),
              ),
            ),

            const SizedBox(height: 24),

            // Budget Tips
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFd2ab17).withOpacity(0.05),
                border: Border.all(
                  color: const Color(0xFFd2ab17).withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: const Color(0xFFd2ab17),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Budget Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00033a),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set realistic budgets based on your spending history. Review and adjust monthly to stay on track with your financial goals.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80), // Bottom navigation space
          ],
        ),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Budget'),
          content: const Text(
            'Budget creation feature will be implemented soon!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// Top-level helper to convert simple color names (or hex strings) to Color.
/*Color _getColorFromString(String colorString) {
  final s = colorString.trim().toLowerCase();
  switch (s) {
    case 'blue':
      return const Color(0xFF163473);
    case 'green':
      return const Color(0xFF10B981);
    case 'red':
      return const Color(0xFFEF4444);
    case 'yellow':
      return const Color(0xFFD2AB17);
    case 'purple':
      return const Color(0xFF8B5CF6);
    default:
      final hex = s.replaceAll('#', '').replaceAll('0x', '');
      if (RegExp(r'^[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?$').hasMatch(hex)) {
        try {
          final value = int.parse(hex, radix: 16);
          final colorValue = hex.length == 6 ? 0xFF000000 | value : value;
          return Color(colorValue);
        } catch (_) {}
      }
      return const Color(0xFF163473);
  }
}*/

class BudgetCard extends StatelessWidget {
  final Budget budget;

  const BudgetCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final percentage = budget.spent / budget.limit;
    final isOverBudget = percentage > 1.0;
    final progressColor = isOverBudget
        ? Colors.red[600]!
        : percentage > 0.8
        ? Colors.orange[600]!
        : _getColorFromString(budget.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _getColorFromString(budget.color).withOpacity(0.2),
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
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getColorFromString(budget.color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  budget.icon,
                  style: TextStyle(
                    fontSize: 20,
                    color: _getColorFromString(budget.color),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00033a),
                      ),
                    ),
                    Text(
                      _getPeriodLabel(budget.period),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6b7280),
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${budget.spent.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                  Text(
                    'of \$${budget.limit.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          Column(
            children: [
              LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFF6b7280).withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}% used',
                    style: TextStyle(
                      fontSize: 12,
                      color: progressColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${(budget.limit - budget.spent).toStringAsFixed(2)} ${isOverBudget ? 'over' : 'left'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverBudget
                          ? Colors.red[600]
                          : const Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (isOverBudget) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 12, color: Colors.red[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Over Budget',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPeriodLabel(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Weekly Budget';
      case BudgetPeriod.monthly:
        return 'Monthly Budget';
      case BudgetPeriod.yearly:
        return 'Yearly Budget';
    }
  }

  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'blue':
        return const Color(0xFF163473);
      case 'green':
        return const Color(0xFF10B981);
      case 'red':
        return const Color(0xFFEF4444);
      case 'yellow':
        return const Color(0xFFD2AB17);
      case 'purple':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF163473);
    }
  }
}
