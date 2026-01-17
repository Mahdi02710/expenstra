import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/unified_data_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/settings_service.dart';
import '../../data/models/budget.dart';
import '../../data/models/transaction.dart';
import 'widgets/budgets_overview.dart';
import 'widgets/budget_list.dart';
import 'widgets/budget_form.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen>
    with AutomaticKeepAliveClientMixin {
  final UnifiedDataService _unifiedService = UnifiedDataService();
  final NotificationService _notificationService = NotificationService();
  final SettingsService _settingsService = SettingsService();
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
                  'Budgets',
                  style: AppTextStyles.h2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.insights),
                    onPressed: _showBudgetInsights,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddBudgetSheet,
                  ),
                ],
              ),

              // Budgets Overview
              StreamBuilder<List<Budget>>(
                stream: _unifiedService.getBudgets(),
                builder: (context, budgetsSnapshot) {
                  return StreamBuilder<List<Transaction>>(
                    stream: _unifiedService.getTransactions(),
                    builder: (context, transactionsSnapshot) {
                      if (!budgetsSnapshot.hasData ||
                          !transactionsSnapshot.hasData) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      final budgets = budgetsSnapshot.data!;
                      final transactions = transactionsSnapshot.data!;

                      // Calculate spent amounts for each budget from transactions
                      final budgetsWithSpent = budgets.map((budget) {
                        double spent = 0.0;
                        final categories = budget.includedCategories ?? [budget.category];
                        
                        for (final tx in transactions) {
                          if (tx.type == TransactionType.expense &&
                              categories.contains(tx.category) &&
                              tx.date.isAfter(budget.startDate.subtract(const Duration(seconds: 1))) &&
                              tx.date.isBefore(budget.endDate.add(const Duration(days: 1)))) {
                            spent += tx.amount;
                          }
                        }

                        return budget.copyWith(spent: spent);
                      }).toList();

                      _notifyBudgetWarnings(budgetsWithSpent);

                      final totalBudgetAmount = budgetsWithSpent.fold(
                        0.0,
                        (sum, budget) => sum + budget.limit,
                      );
                      final totalSpent = budgetsWithSpent.fold(
                        0.0,
                        (sum, budget) => sum + budget.spent,
                      );

                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: BudgetsOverview(
                            budgets: budgetsWithSpent,
                            totalBudgetAmount: totalBudgetAmount,
                            totalSpent: totalSpent,
                          ),
                        ),
                      );
                    },
                  );
                },
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
                        'Your Budgets',
                        style: AppTextStyles.h3.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: _showBudgetTemplates,
                        child: Text(
                          'Templates',
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

              // Budget List
              StreamBuilder<List<Budget>>(
                stream: _unifiedService.getBudgets(),
                builder: (context, budgetsSnapshot) {
                  return StreamBuilder<List<Transaction>>(
                    stream: _unifiedService.getTransactions(),
                    builder: (context, transactionsSnapshot) {
                      if (budgetsSnapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading budgets',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      if (budgetsSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          transactionsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      final budgets = budgetsSnapshot.data ?? [];
                      final transactions = transactionsSnapshot.data ?? [];

                      // Calculate spent amounts for each budget
                      final budgetsWithSpent = budgets.map((budget) {
                        double spent = 0.0;
                        final categories = budget.includedCategories ?? [budget.category];
                        
                        for (final tx in transactions) {
                          if (tx.type == TransactionType.expense &&
                              categories.contains(tx.category) &&
                              tx.date.isAfter(budget.startDate.subtract(const Duration(seconds: 1))) &&
                              tx.date.isBefore(budget.endDate.add(const Duration(days: 1)))) {
                            spent += tx.amount;
                          }
                        }

                        return budget.copyWith(spent: spent);
                      }).toList();

                      return SliverToBoxAdapter(
                        child: BudgetList(
                          budgets: budgetsWithSpent,
                          onBudgetTap: _onBudgetTap,
                        ),
                      );
                    },
                  );
                },
              ),

              // Quick Tips Section
              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickTips(),
                ),
              ),

              // Bottom padding for navigation bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetSheet,
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

  Widget _buildQuickTips() {
    final tips = [
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Budget Smart',
        'subtitle': 'Use the 50/30/20 rule: 50% needs, 30% wants, 20% savings',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.trending_up,
        'title': 'Track Progress',
        'subtitle': 'Review your budgets weekly to stay on track',
        'color': AppColors.income,
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Set Alerts',
        'subtitle': 'Get notified when you reach 80% of your budget',
        'color': AppColors.warning,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Tips',
          style: AppTextStyles.h3.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        ...tips.map(
          (tip) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (tip['color'] as Color).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (tip['color'] as Color).withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (tip['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tip['icon'] as IconData,
                    color: tip['color'] as Color,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title'] as String,
                        style: AppTextStyles.subtitle1.copyWith(
                          color: tip['color'] as Color,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        tip['subtitle'] as String,
                        style: AppTextStyles.body2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {});
    }
  }

  void _onBudgetTap(String budgetId) {
    // Budget details will be shown via StreamBuilder

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<List<Budget>>(
        stream: _unifiedService.getBudgets(),
        builder: (context, budgetsSnapshot) {
          return StreamBuilder<List<Transaction>>(
            stream: _unifiedService.getTransactions(),
            builder: (context, transactionsSnapshot) {
              if (!budgetsSnapshot.hasData || !transactionsSnapshot.hasData) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final budgets = budgetsSnapshot.data!;
              final transactions = transactionsSnapshot.data!;
              final budget = budgets.firstWhere(
                (b) => b.id == budgetId,
                orElse: () => budgets.first,
              );

              // Calculate spent from transactions
              double spent = 0.0;
              final categories = budget.includedCategories ?? [budget.category];
              
              for (final tx in transactions) {
                if (tx.type == TransactionType.expense &&
                    categories.contains(tx.category) &&
                    tx.date.isAfter(budget.startDate.subtract(const Duration(seconds: 1))) &&
                    tx.date.isBefore(budget.endDate.add(const Duration(days: 1)))) {
                  spent += tx.amount;
                }
              }

              final budgetWithSpent = budget.copyWith(spent: spent);
              final isDark = Theme.of(context).brightness == Brightness.dark;

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

                    // Budget header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: budgetWithSpent.isOverBudget
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : budgetWithSpent.isNearLimit
                                      ? AppColors.warning.withValues(alpha: 0.1)
                                      : AppColors.primaryWithOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                budgetWithSpent.icon,
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(budgetWithSpent.name, style: AppTextStyles.h2),

                          Text(budgetWithSpent.periodLabel, style: AppTextStyles.body2),

                          const SizedBox(height: 16),

                          // Progress indicator
                          Column(
                            children: [
                              Text(
                                '${budgetWithSpent.formattedSpent} of ${budgetWithSpent.formattedLimit}',
                                style: AppTextStyles.h4,
                              ),

                              const SizedBox(height: 8),

                              LinearProgressIndicator(
                                value: budgetWithSpent.percentage.clamp(0.0, 1.0),
                                backgroundColor: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  budgetWithSpent.isOverBudget
                                      ? AppColors.error
                                      : budgetWithSpent.isNearLimit
                                          ? AppColors.warning
                                          : AppColors.primary,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    budgetWithSpent.statusEmoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    budgetWithSpent.status,
                                    style: AppTextStyles.body2.copyWith(
                                      color: budgetWithSpent.isOverBudget
                                          ? AppColors.error
                                          : budgetWithSpent.isNearLimit
                                              ? AppColors.warning
                                              : AppColors.income,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Budget details
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBudgetDetailRow('Category', budgetWithSpent.category),
                            _buildBudgetDetailRow('Period', budgetWithSpent.periodShortLabel),
                            _buildBudgetDetailRow(
                              'Spent',
                              budgetWithSpent.formattedSpent,
                            ),
                            _buildBudgetDetailRow(
                              'Limit',
                              budgetWithSpent.formattedLimit,
                            ),
                            _buildBudgetDetailRow(
                              'Remaining',
                              budgetWithSpent.formattedRemaining,
                            ),
                            _buildBudgetDetailRow(
                              'Progress',
                              '${budgetWithSpent.formattedPercentage} (${budgetWithSpent.status})',
                            ),
                            _buildBudgetDetailRow(
                              'Days Left',
                              budgetWithSpent.daysRemainingText,
                            ),
                            if (budgetWithSpent.includedCategories != null &&
                                budgetWithSpent.includedCategories!.length > 1)
                              _buildBudgetDetailRow(
                                'Categories',
                                budgetWithSpent.includedCategories!.join(', '),
                              ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: budgetWithSpent.isOverBudget
                                    ? AppColors.error.withValues(alpha: 0.1)
                                    : budgetWithSpent.isNearLimit
                                        ? AppColors.warning.withValues(alpha: 0.1)
                                        : AppColors.income.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: budgetWithSpent.isOverBudget
                                      ? AppColors.error.withValues(alpha: 0.3)
                                      : budgetWithSpent.isNearLimit
                                          ? AppColors.warning.withValues(alpha: 0.3)
                                          : AppColors.income.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        size: 20,
                                        color: budgetWithSpent.isOverBudget
                                            ? AppColors.error
                                            : budgetWithSpent.isNearLimit
                                                ? AppColors.warning
                                                : AppColors.income,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Spending Advice',
                                        style: AppTextStyles.subtitle1.copyWith(
                                          color: budgetWithSpent.isOverBudget
                                              ? AppColors.error
                                              : budgetWithSpent.isNearLimit
                                                  ? AppColors.warning
                                                  : AppColors.income,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    budgetWithSpent.spendingAdvice,
                                    style: AppTextStyles.body2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _editBudget(budgetWithSpent),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _deleteBudget(budgetWithSpent),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBudgetDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: AppTextStyles.body2)),
          Expanded(child: Text(value, style: AppTextStyles.body1)),
        ],
      ),
    );
  }

  void _showAddBudgetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetForm(),
    ).then((result) {
      if (result != null && result is Budget) {
        _unifiedService
            .addBudget(result)
            .then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Budget created successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            })
            .catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${error.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            });
      }
    });
  }

  void _editBudget(Budget budget) {
    Navigator.pop(context); // Close detail sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetForm(budget: budget),
    ).then((result) {
      if (result != null && result is Budget) {
        _unifiedService
            .updateBudget(result)
            .then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Budget updated successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            })
            .catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${error.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            });
      }
    });
  }

  void _deleteBudget(Budget budget) {
    Navigator.pop(context); // Close detail sheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete "${budget.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _unifiedService
                  .deleteBudget(budget.id)
                  .then((_) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Budget deleted successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  })
                  .catchError((error) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${error.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  });
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBudgetInsights() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Budget Insights'),
        content: const Text('Budget insights and analytics coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _notifyBudgetWarnings(List<Budget> budgets) {
    if (!_settingsService.notificationsEnabled.value) {
      return;
    }
    for (final budget in budgets) {
      if (budget.isOverBudget) {
        _notificationService.showBudgetWarning(
          budgetId: budget.id,
          budgetName: budget.name,
          status: 'You are over budget. Review your spending.',
        );
      } else if (budget.isNearLimit) {
        _notificationService.showBudgetWarning(
          budgetId: budget.id,
          budgetName: budget.name,
          status: 'You are close to your limit.',
        );
      }
    }
  }

  void _showBudgetTemplates() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Budget Templates'),
        content: const Text('Budget templates coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
