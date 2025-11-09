import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/data_service.dart';
import 'widgets/budgets_overview.dart';
import 'widgets/budget_list.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen>
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
                backgroundColor: Colors.transparent,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BudgetsOverview(
                    budgets: _dataService.budgets,
                    totalBudgetAmount: _dataService.budgets.fold(
                      0.0, (sum, budget) => sum + budget.limit,
                    ),
                    totalSpent: _dataService.budgets.fold(
                      0.0, (sum, budget) => sum + budget.spent,
                    ),
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
                            color: Theme.of(context).brightness == Brightness.dark
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
              SliverToBoxAdapter(
                child: BudgetList(
                  budgets: _dataService.budgets,
                  onBudgetTap: _onBudgetTap,
                ),
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
        
        ...tips.map((tip) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (tip['color'] as Color).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (tip['color'] as Color).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (tip['color'] as Color).withOpacity(0.1),
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
        )),
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
    final budget = _dataService.getBudget(budgetId);
    if (budget == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                      color: AppColors.primaryWithOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        budget.icon,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    budget.name,
                    style: AppTextStyles.h2,
                  ),
                  
                  Text(
                    budget.periodLabel,
                    style: AppTextStyles.body2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress indicator
                  Column(
                    children: [
                      Text(
                        '${budget.formattedSpent} of ${budget.formattedLimit}',
                        style: AppTextStyles.h4,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      LinearProgressIndicator(
                        value: budget.percentage,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          budget.isOverBudget ? AppColors.error : AppColors.primary,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        budget.status,
                        style: AppTextStyles.body2.copyWith(
                          color: budget.isOverBudget ? AppColors.error : AppColors.income,
                        ),
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
                    _buildBudgetDetailRow('Category', budget.category),
                    _buildBudgetDetailRow('Period', budget.periodShortLabel),
                    _buildBudgetDetailRow('Remaining', budget.formattedRemaining),
                    _buildBudgetDetailRow('Progress', budget.formattedPercentage),
                    _buildBudgetDetailRow('Days Left', budget.daysRemainingText),
                    const SizedBox(height: 16),
                    Text(
                      'Spending Advice',
                      style: AppTextStyles.subtitle1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      budget.spendingAdvice,
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.body2,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body1,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Create New Budget',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: 16),
            const Text('Budget creation form would go here'),
            // Implement actual form
          ],
        ),
      ),
    );
  }

  void _showBudgetInsights() {
    // Show budget insights and analytics
  }

  void _showBudgetTemplates() {
    // Show budget templates
  }
}