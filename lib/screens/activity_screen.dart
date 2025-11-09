import 'package:flutter/material.dart';
import '../data/services/data_service.dart';
import '../data/models/transaction.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    final weeklyTransactions = dataService.getTransactionsThisWeek();
    
    // Generate weekly data from transactions
    final weeklyData = <ChartData>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTransactions = weeklyTransactions.where((t) => 
        t.date.day == date.day && t.date.month == date.month && t.date.year == date.year
      ).toList();
      final dayTotal = dayTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      weeklyData.add(ChartData(dayName, dayTotal));
    }

    // Get category spending data
    final categorySpending = dataService.getSpendingByCategory();
    final totalSpending = categorySpending.values.fold(0.0, (sum, amount) => sum + amount);
    
    final categoryData = categorySpending.entries.map((entry) {
      final percentage = totalSpending > 0 ? (entry.value / totalSpending * 100) : 0.0;
      return CategorySpending(
        entry.key, 
        entry.value, 
        const Color(0xFF163473), 
        percentage
      );
    }).toList();

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
                  'Activity',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00033a),
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
                  child: const Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFd2ab17),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weekly Overview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF163473),
                    Color(0xFF162647),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week\'s Spending',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$${dataService.getTotalExpenses(period: Duration(days: 7)).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Colors.red[300],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+12.5% from last week',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[300],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Weekly Chart
            const Text(
              'Daily Spending',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00033a),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF162647).withOpacity(0.1),
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
                  SizedBox(
                    height: 200,
                    child: SimpleBarChart(data: weeklyData),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Average daily spending: \$${(dataService.getTotalExpenses(period: Duration(days: 7)) / 7).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category Breakdown
            const Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00033a),
              ),
            ),
            const SizedBox(height: 12),

            ...categoryData.map((category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CategoryCard(category: category),
            )),

            const SizedBox(height: 24),

            // Insights Card
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
                        Icons.insights,
                        size: 20,
                        color: const Color(0xFFd2ab17),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Spending Insights',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00033a),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InsightItem(
                    icon: Icons.trending_up,
                    text: 'Food spending increased by 15% this week',
                    color: Colors.orange[600]!,
                  ),
                  const SizedBox(height: 8),
                  _InsightItem(
                    icon: Icons.check_circle,
                    text: 'You stayed within your entertainment budget',
                    color: Colors.green[600]!,
                  ),
                  const SizedBox(height: 8),
                  _InsightItem(
                    icon: Icons.info,
                    text: 'Most spending occurs on weekends',
                    color: const Color(0xFF163473),
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
}

class SimpleBarChart extends StatelessWidget {
  final List<ChartData> data;

  const SimpleBarChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final height = (item.value / maxValue) * 160;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '\$${item.value.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6b7280),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: height,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF163473),
                    Color(0xFFd2ab17),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF00033a),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final CategorySpending category;

  const CategoryCard({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: category.color.withOpacity(0.2),
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
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Category info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00033a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${category.percentage.toStringAsFixed(1)}% of total spending',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '\$${category.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6b7280),
            ),
          ),
        ),
      ],
    );
  }
}

class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}

class CategorySpending {
  final String name;
  final double amount;
  final Color color;
  final double percentage;

  CategorySpending(this.name, this.amount, this.color, this.percentage);
}