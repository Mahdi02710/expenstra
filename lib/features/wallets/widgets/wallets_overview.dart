import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class WalletsOverview extends StatelessWidget {
  final double totalBalance;
  final double totalDebt;
  final int walletCount;

  const WalletsOverview({
    super.key,
    required this.totalBalance,
    required this.totalDebt,
    required this.walletCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final netWorth = totalBalance - totalDebt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Overview',
                style: AppTextStyles.h4.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.gold : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$walletCount WALLETS',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.gold : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Net Worth
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Worth',
                style: AppTextStyles.body2.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                formatter.format(netWorth),
                style: AppTextStyles.currencyLarge.copyWith(
                  color: netWorth >= 0 ? AppColors.income : AppColors.expense,
                  fontSize: 28,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Assets and Liabilities
          Row(
            children: [
              // Assets
              Expanded(
                child: _buildFinancialMetric(
                  label: 'Assets',
                  amount: totalBalance,
                  color: AppColors.income,
                  icon: Icons.trending_up,
                ),
              ),

              const SizedBox(width: 16),

              // Liabilities
              Expanded(
                child: _buildFinancialMetric(
                  label: 'Liabilities',
                  amount: totalDebt,
                  color: AppColors.expense,
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),

          if (totalDebt > 0) ...[
            const SizedBox(height: 16),

            // Debt to Assets Ratio
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debt-to-Asset Ratio',
                          style: AppTextStyles.subtitle2.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        Text(
                          '${((totalDebt / totalBalance) * 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
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

  Widget _buildFinancialMetric({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 12),
              ),

              const SizedBox(width: 8),

              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            formatter.format(amount),
            style: AppTextStyles.subtitle1.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
