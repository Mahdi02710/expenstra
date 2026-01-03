import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/data_service.dart';
import 'widgets/spending_chart.dart';
import 'widgets/category_breakdown.dart';
import 'widgets/monthly_summary.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final DataService _dataService = DataService();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last 3 Months',
    'This Year',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                title: Text(
                  'Activity',
                  style: AppTextStyles.h2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                centerTitle: false,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.date_range),
                    onSelected: (period) {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                    itemBuilder: (context) => _periods
                        .map(
                          (period) =>
                              PopupMenuItem(value: period, child: Text(period)),
                        )
                        .toList(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.insights),
                    onPressed: _showDetailedAnalytics,
                  ),
                ],
              ),

              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Categories'),
                      Tab(text: 'Trends'),
                    ],
                    labelColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.gold
                        : AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? AppColors.gold
                        : AppColors.primary,
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildCategoriesTab(),
              _buildTrendsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Summary
            MonthlySummary(
              income: _dataService.getTotalIncome(
                period: const Duration(days: 30),
              ),
              expenses: _dataService.getTotalExpenses(
                period: const Duration(days: 30),
              ),
              transactions: _dataService.getTransactionsThisMonth(),
            ),

            const SizedBox(height: 24),

            // Spending Chart
            Text(
              'Spending Overview',
              style: AppTextStyles.h3.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            SpendingChart(
              spendingData: _dataService.getSpendingByCategory(
                period: const Duration(days: 30),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CategoryBreakdown(
            categorySpending: _dataService.getSpendingByCategory(
              period: const Duration(days: 30),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Trends',
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          _buildTrendChart(),

          const SizedBox(height: 24),

          _buildTrendInsights(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final transactions = _dataService.getTransactionsThisMonth();
    final averageTransaction = transactions.isNotEmpty
        ? transactions.fold<double>(0, (sum, t) => sum + t.amount) /
              transactions.length
        : 0.0;

    final stats = [
      {
        'title': 'Transactions',
        'value': transactions.length.toString(),
        'subtitle': 'This month',
        'icon': Icons.receipt_long,
        'color': AppColors.primary,
      },
      {
        'title': 'Average',
        'value': '\$${averageTransaction.toStringAsFixed(0)}',
        'subtitle': 'Per transaction',
        'icon': Icons.trending_up,
        'color': AppColors.income,
      },
      {
        'title': 'Categories',
        'value': _dataService.getAllCategories().length.toString(),
        'subtitle': 'Used this month',
        'icon': Icons.category,
        'color': AppColors.gold,
      },
      {
        'title': 'Wallets',
        'value': _dataService.wallets.length.toString(),
        'subtitle': 'Active accounts',
        'icon': Icons.account_balance_wallet,
        'color': AppColors.secondary,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: AppTextStyles.h3.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = 2;
            final crossAxisSpacing = 16.0;
            final mainAxisSpacing = 16.0;
            final width = (constraints.maxWidth - crossAxisSpacing) / crossAxisCount;
            final mainAxisExtent = width * 1.3; // Increased from 1.2 to 1.3 to prevent overflow

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                mainAxisExtent: mainAxisExtent,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (stat['color'] as Color).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (stat['color'] as Color).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          stat['icon'] as IconData,
                          color: stat['color'] as Color,
                          size: 16,
                        ),
                      ),

                      const Spacer(),

                      Flexible(
                        child: Text(
                          stat['value'] as String,
                          style: AppTextStyles.h3.copyWith(
                            color: stat['color'] as Color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        stat['title'] as String,
                        style: AppTextStyles.body2.copyWith(
                          color: stat['color'] as Color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      Text(
                        stat['subtitle'] as String,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Center(child: Text('Trend chart would go here')),
    );
  }

  Widget _buildTrendInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: AppTextStyles.h4.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        _buildInsightCard(
          icon: Icons.trending_down,
          title: 'Spending Decreased',
          subtitle: 'You spent 15% less this month compared to last month',
          color: AppColors.income,
        ),

        const SizedBox(height: 12),

        _buildInsightCard(
          icon: Icons.category,
          title: 'Top Category',
          subtitle: 'Food & Dining accounts for 35% of your spending',
          color: AppColors.primary,
        ),

        const SizedBox(height: 12),

        _buildInsightCard(
          icon: Icons.schedule,
          title: 'Peak Spending Time',
          subtitle: 'Most transactions happen between 12-2 PM',
          color: AppColors.gold,
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle1.copyWith(color: color),
                ),

                const SizedBox(height: 2),

                Text(subtitle, style: AppTextStyles.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {});
    }
  }

  void _showDetailedAnalytics() {
    // Show detailed analytics screen
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
