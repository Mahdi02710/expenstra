import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CategoryBreakdown extends StatelessWidget {
  final Map<String, double> categorySpending;

  const CategoryBreakdown({
    super.key,
    required this.categorySpending,
  });

  @override
  Widget build(BuildContext context) {
    if (categorySpending.isEmpty) {
      return _buildEmptyState(context);
    }

    final total = categorySpending.values.fold<double>(0, (sum, value) => sum + value);
    final sortedEntries = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: AppTextStyles.h3.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value.key;
          final amount = entry.value.value;
          final percentage = total > 0 ? (amount / total) : 0.0;
          
          return _buildCategoryItem(
            category: category,
            amount: amount,
            percentage: percentage,
            color: AppColors.getChartColor(index),
          );
        }),
      ],
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
              Icons.category,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'No spending data',
            style: AppTextStyles.h4,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Your category breakdown will appear here once you start making transactions.',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String category,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Category header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Text(
                    category,
                    style: AppTextStyles.subtitle1.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(amount),
                    style: AppTextStyles.subtitle1.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.caption.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}