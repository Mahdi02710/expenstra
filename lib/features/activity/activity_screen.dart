import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/unified_data_service.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/services/analytics_service.dart';
import '../../data/models/analytics_summary.dart';
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
  final UnifiedDataService _unifiedService = UnifiedDataService();
  final AnalyticsService _analyticsService = AnalyticsService();
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
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppTextStyles.subtitle2.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: AppTextStyles.subtitle2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
      child: StreamBuilder<List<Transaction>>(
        stream: _unifiedService.getTransactions(),
        builder: (context, transactionsSnapshot) {
          if (transactionsSnapshot.hasError) {
            return SingleChildScrollView(
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
                      'Error loading transactions',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          if (transactionsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = transactionsSnapshot.data ?? [];
          final now = DateTime.now();
          final thisMonthStart = DateTime(now.year, now.month);

          // Calculate this month's transactions
          final thisMonthTransactions = transactions.where((tx) {
            return tx.date.isAfter(
                  thisMonthStart.subtract(const Duration(seconds: 1)),
                ) ||
                tx.date.isAtSameMomentAs(thisMonthStart);
          }).toList();

          // Calculate income and expenses
          double income = 0.0;
          double expenses = 0.0;
          for (final tx in thisMonthTransactions) {
            if (tx.type == TransactionType.income) {
              income += tx.amount;
            } else if (tx.type == TransactionType.expense) {
              expenses += tx.amount;
            }
          }

          // Calculate spending by category
          final Map<String, double> categorySpending = {};
          for (final tx in thisMonthTransactions) {
            if (tx.type == TransactionType.expense) {
              categorySpending[tx.category] =
                  (categorySpending[tx.category] ?? 0.0) + tx.amount;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly Summary
                MonthlySummary(
                  income: income,
                  expenses: expenses,
                  transactions: thisMonthTransactions,
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

                const SizedBox(height: 26),

                SpendingChart(spendingData: categorySpending),

                const SizedBox(height: 24),

                // Quick Stats
                _buildQuickStats(transactions, categorySpending),

                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return StreamBuilder<List<Transaction>>(
      stream: _unifiedService.getTransactions(),
      builder: (context, transactionsSnapshot) {
        if (transactionsSnapshot.hasError) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading transactions',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        if (transactionsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = transactionsSnapshot.data ?? [];
        final now = DateTime.now();
        final thisMonthStart = DateTime(now.year, now.month);

        // Calculate spending by category for this month
        final Map<String, double> categorySpending = {};
        for (final tx in transactions) {
          if (tx.type == TransactionType.expense &&
              (tx.date.isAfter(
                    thisMonthStart.subtract(const Duration(seconds: 1)),
                  ) ||
                  tx.date.isAtSameMomentAs(thisMonthStart))) {
            categorySpending[tx.category] =
                (categorySpending[tx.category] ?? 0.0) + tx.amount;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CategoryBreakdown(categorySpending: categorySpending),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    return StreamBuilder<AnalyticsSummary?>(
      stream: _analyticsService.getSummary(),
      builder: (context, analyticsSnapshot) {
        final summary = analyticsSnapshot.data;
        if (summary != null && summary.monthlyTotals.isNotEmpty) {
          return _buildTrendsFromAnalytics(summary);
        }
        return _buildTrendsFromTransactions();
      },
    );
  }

  Widget _buildTrendsFromAnalytics(AnalyticsSummary summary) {
    final months = summary.monthlyTotals.map((total) => total.month).toList()
      ..sort((a, b) => a.compareTo(b));
    final monthlyTotals = <DateTime, double>{
      for (final total in summary.monthlyTotals) total.month: total.value,
    };
    final forecast = summary.forecast?.nextMonth ?? 0.0;
    final insights = summary.insights.map(_mapAnalyticsInsight).toList();
    final forecastExplanation = summary.forecast?.explanation ?? '';
    if (forecastExplanation.isNotEmpty) {
      insights.insert(
        0,
        _TrendInsight(
          icon: Icons.auto_graph,
          title: 'Next month forecast',
          subtitle: forecastExplanation,
          color: AppColors.gold,
        ),
      );
    }

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
          _buildTrendChart(months, monthlyTotals, forecast),
          const SizedBox(height: 24),
          _buildTrendInsights(insights),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTrendsFromTransactions() {
    return StreamBuilder<List<Transaction>>(
      stream: _unifiedService.getTransactions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading transactions',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data ?? [];
        final expenses = transactions
            .where((tx) => tx.type == TransactionType.expense)
            .toList();

        if (expenses.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.show_chart, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No spending data yet.',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final months = _recentMonths(5);
        final monthlyTotals = <DateTime, double>{
          for (final m in months) m: 0.0,
        };
        final categoryMonthly = <String, List<double>>{};

        for (final tx in expenses) {
          final key = _monthKey(tx.date);
          if (!monthlyTotals.containsKey(key)) continue;
          monthlyTotals[key] = (monthlyTotals[key] ?? 0) + tx.amount;

          categoryMonthly.putIfAbsent(
            tx.category,
            () => List<double>.filled(months.length, 0),
          );
          final index = months.indexOf(key);
          if (index >= 0) {
            categoryMonthly[tx.category]![index] += tx.amount;
          }
        }

        final lastThree = months
            .skip(months.length - 3)
            .map((m) => monthlyTotals[m] ?? 0)
            .toList();
        final forecast = lastThree.isEmpty
            ? 0.0
            : lastThree.reduce((a, b) => a + b) / lastThree.length;

        final topCategory = categoryMonthly.entries
            .fold<MapEntry<String, List<double>>?>(null, (prev, entry) {
              final avg = entry.value.isEmpty
                  ? 0.0
                  : entry.value.reduce((a, b) => a + b) / entry.value.length;
              final prevAvg = prev == null
                  ? -1
                  : prev.value.reduce((a, b) => a + b) / prev.value.length;
              return avg > prevAvg ? entry : prev;
            });

        final insights = <_TrendInsight>[];
        final lastMonth = months.last;
        final lastMonthSpend = monthlyTotals[lastMonth] ?? 0.0;
        final priorAvg = months.length > 1
            ? monthlyTotals.entries
                      .where((e) => e.key != lastMonth)
                      .fold<double>(0, (sum, e) => sum + e.value) /
                  (months.length - 1)
            : 0.0;
        if (priorAvg > 0 && lastMonthSpend > priorAvg * 1.3) {
          insights.add(
            _TrendInsight(
              icon: Icons.warning_amber,
              title: 'Spending spike detected',
              subtitle:
                  'Last month spending was ${(lastMonthSpend / priorAvg * 100).toStringAsFixed(0)}% of your recent average.',
              color: AppColors.warning,
            ),
          );
        }

        if (topCategory != null) {
          final avg =
              topCategory.value.reduce((a, b) => a + b) /
              topCategory.value.length;
          insights.add(
            _TrendInsight(
              icon: Icons.trending_up,
              title: 'Likely top category next month',
              subtitle:
                  '${topCategory.key} is projected at \$${avg.toStringAsFixed(0)}.',
              color: AppColors.primary,
            ),
          );
        }

        final totalThisMonth = monthlyTotals[lastMonth] ?? 0;
        if (totalThisMonth > 0) {
          final topShare = topCategory == null || topCategory.value.isEmpty
              ? 0.0
              : (topCategory.value.last / totalThisMonth);
          if (topShare >= 0.3) {
            insights.add(
              _TrendInsight(
                icon: Icons.notifications_active,
                title: 'Consider a budget',
                subtitle:
                    '${topCategory!.key} is ${((topShare) * 100).toStringAsFixed(0)}% of last month spending.',
                color: AppColors.error,
              ),
            );
          }
        }

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
              _buildTrendChart(months, monthlyTotals, forecast),
              const SizedBox(height: 24),
              _buildTrendInsights(insights),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  _TrendInsight _mapAnalyticsInsight(AnalyticsInsight insight) {
    IconData icon;
    Color color;
    switch (insight.type) {
      case 'spike':
        icon = Icons.warning_amber;
        color = AppColors.warning;
        break;
      case 'anomaly':
        icon = Icons.report_problem_outlined;
        color = AppColors.error;
        break;
      case 'top_category':
        icon = Icons.trending_up;
        color = AppColors.primary;
        break;
      case 'volatility':
        icon = Icons.show_chart;
        color = AppColors.gold;
        break;
      default:
        icon = Icons.insights;
        color = AppColors.primary;
    }

    return _TrendInsight(
      icon: icon,
      title: insight.title,
      subtitle: insight.detail,
      color: color,
    );
  }

  Widget _buildQuickStats(
    List<Transaction> transactions,
    Map<String, double> categorySpending,
  ) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month);
    final thisMonthTransactions = transactions.where((tx) {
      return tx.date.isAfter(
            thisMonthStart.subtract(const Duration(seconds: 1)),
          ) ||
          tx.date.isAtSameMomentAs(thisMonthStart);
    }).toList();

    final averageTransaction = thisMonthTransactions.isNotEmpty
        ? thisMonthTransactions.fold<double>(0, (sum, t) => sum + t.amount) /
              thisMonthTransactions.length
        : 0.0;

    return StreamBuilder<List<Wallet>>(
      stream: _unifiedService.getWallets(),
      builder: (context, walletsSnapshot) {
        final walletCount = walletsSnapshot.data?.length ?? 0;

        final stats = [
          {
            'title': 'Transactions',
            'value': thisMonthTransactions.length.toString(),
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
            'value': categorySpending.keys.length.toString(),
            'subtitle': 'Used this month',
            'icon': Icons.category,
            'color': AppColors.gold,
          },
          {
            'title': 'Wallets',
            'value': walletCount.toString(),
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
                final width =
                    (constraints.maxWidth - crossAxisSpacing) / crossAxisCount;
                final mainAxisExtent = width * 1;

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
                          color: (stat['color'] as Color).withValues(
                            alpha: 0.2,
                          ),
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
                              color: (stat['color'] as Color).withValues(
                                alpha: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              stat['icon'] as IconData,
                              color: stat['color'] as Color,
                              size: 18,
                            ),
                          ),

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
      },
    );
  }

  Widget _buildTrendChart(
    List<DateTime> months,
    Map<DateTime, double> monthlyTotals,
    double forecast,
  ) {
    final maxValue = [
      ...monthlyTotals.values,
      forecast,
    ].fold<double>(0, (max, v) => v > max ? v : max);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= months.length + 1) {
                    return const SizedBox.shrink();
                  }
                  if (index == months.length) {
                    return Text('Next', style: AppTextStyles.caption);
                  }
                  final month = DateFormat('MMM').format(months[index]);
                  return Text(month, style: AppTextStyles.caption);
                },
              ),
            ),
          ),
          maxY: maxValue == 0 ? 1 : maxValue * 1.2,
          barGroups: [
            for (var i = 0; i < months.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: monthlyTotals[months[i]] ?? 0,
                    width: 12,
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.primary,
                  ),
                ],
              ),
            BarChartGroupData(
              x: months.length,
              barRods: [
                BarChartRodData(
                  toY: forecast,
                  width: 12,
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.gold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendInsights(List<_TrendInsight> insights) {
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
        if (insights.isEmpty)
          Text(
            'No significant trends yet. Keep tracking to build insights.',
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          )
        else
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInsightCard(
                icon: insight.icon,
                title: insight.title,
                subtitle: insight.subtitle,
                color: insight.color,
              ),
            ),
          ),
      ],
    );
  }

  List<DateTime> _recentMonths(int count) {
    final now = DateTime.now();
    return List.generate(
      count,
      (index) => DateTime(now.year, now.month - (count - 1 - index)),
    );
  }

  DateTime _monthKey(DateTime date) {
    return DateTime(date.year, date.month);
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Detailed Analytics',
              style: AppTextStyles.h3.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'More insights are coming soon.',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
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

class _TrendInsight {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _TrendInsight({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
