import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/budget.dart';

class BudgetsOverview extends StatelessWidget {
  final List<Budget> budgets;
  final double totalBudgetAmount;
  final double totalSpent;

  const BudgetsOverview({
    super.key,
    required this.budgets,
    required this.totalBudgetAmount,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final overallProgress = totalBudgetAmount > 0
        ? (totalSpent / totalBudgetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remaining = (totalBudgetAmount - totalSpent).clamp(
      0.0,
      double.infinity,
    );
    final overBudgetCount = budgets.where((b) => b.isOverBudget).length;
    final nearLimitCount = budgets
        .where((b) => b.isNearLimit && !b.isOverBudget)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.goldGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.gold : AppColors.primary).withValues(
              alpha: 0.3,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Overview',
                style: AppTextStyles.h4.copyWith(color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${budgets.length} BUDGETS',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Overall progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Budget Progress',
                style: AppTextStyles.body2.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${formatter.format(totalSpent)} of ${formatter.format(totalBudgetAmount)}',
                style: AppTextStyles.currencyMedium.copyWith(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // Progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: overallProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${(overallProgress * 100).toStringAsFixed(1)}% used • ${formatter.format(remaining)} remaining',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Budget status indicators
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // On track budgets
                Expanded(
                  child: _buildStatusIndicator(
                    count: budgets.length - overBudgetCount - nearLimitCount,
                    label: 'On Track',
                    color: Colors.white,
                    icon: Icons.check_circle_outline,
                  ),
                ),

                // Near limit budgets
                if (nearLimitCount > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusIndicator(
                      count: nearLimitCount,
                      label: 'Near Limit',
                      color: Colors.white.withValues(alpha: 0.8),
                      icon: Icons.warning_amber_outlined,
                    ),
                  ),
                ],

                // Over budget
                if (overBudgetCount > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusIndicator(
                      count: overBudgetCount,
                      label: 'Over Budget',
                      color: Colors.white.withValues(alpha: 0.7),
                      icon: Icons.error_outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: AppTextStyles.h4.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
