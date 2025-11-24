import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/budget.dart';

class BudgetList extends StatelessWidget {
  final List<Budget> budgets;
  final Function(String) onBudgetTap;

  const BudgetList({
    super.key,
    required this.budgets,
    required this.onBudgetTap,
  });

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: budgets
            .map(
              (budget) => BudgetCard(
                budget: budget,
                onTap: () => onBudgetTap(budget.id),
              ),
            )
            .toList(),
      ),
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
              Icons.track_changes,
              size: 40,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 16),

          Text('No budgets yet', style: AppTextStyles.h4),

          const SizedBox(height: 8),

          Text(
            'Create your first budget to start tracking your spending goals.',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class BudgetCard extends StatefulWidget {
  final Budget budget;
  final VoidCallback onTap;

  const BudgetCard({super.key, required this.budget, required this.onTap});

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getBorderColor(), width: 1),
                boxShadow: [
                  if (widget.budget.isOverBudget)
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Budget icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getStatusColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            widget.budget.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Budget info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.budget.name,
                                    style: AppTextStyles.subtitle1.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.budget.statusEmoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),

                            const SizedBox(height: 2),

                            Text(
                              '${widget.budget.category} • ${widget.budget.periodShortLabel}',
                              style: AppTextStyles.body2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount spent vs limit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.budget.formattedSpent,
                            style: AppTextStyles.subtitle1.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'of ${widget.budget.formattedLimit}',
                            style: AppTextStyles.body2,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Progress bar
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.budget.percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Status and progress info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.budget.formattedPercentage,
                            style: AppTextStyles.caption.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.budget.daysRemainingText,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Status message
                  if (widget.budget.isOverBudget ||
                      widget.budget.isNearLimit) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.budget.isOverBudget
                                ? Icons.error_outline
                                : Icons.warning_amber_outlined,
                            color: _getStatusColor(),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.budget.status,
                              style: AppTextStyles.caption.copyWith(
                                color: _getStatusColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor() {
    if (widget.budget.isOverBudget) {
      return AppColors.error;
    } else if (widget.budget.isNearLimit) {
      return AppColors.warning;
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark ? AppColors.gold : AppColors.primary;
    }
  }

  Color _getBorderColor() {
    if (widget.budget.isOverBudget) {
      return AppColors.error.withValues(alpha: 0.3);
    } else if (widget.budget.isNearLimit) {
      return AppColors.warning.withValues(alpha: 0.3);
    } else {
      return Theme.of(context).dividerColor;
    }
  }
}
