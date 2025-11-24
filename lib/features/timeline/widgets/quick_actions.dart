import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onTransfer;

  const QuickActions({
    super.key,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.h4.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // Add Income
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_circle,
                  label: 'Add Income',
                  color: AppColors.income,
                  onTap: onAddIncome,
                ),
              ),

              const SizedBox(width: 12),

              // Add Expense
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.remove_circle,
                  label: 'Add Expense',
                  color: AppColors.expense,
                  onTap: onAddExpense,
                ),
              ),

              const SizedBox(width: 12),

              // Transfer
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Transfer',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.gold
                      : AppColors.primary,
                  onTap: onTransfer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.label,
                    style: AppTextStyles.caption.copyWith(
                      color: widget.color,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
