import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SpendingChart extends StatelessWidget {
  final Map<String, double> spendingData;

  const SpendingChart({super.key, required this.spendingData});

  @override
  Widget build(BuildContext context) {
    if (spendingData.isEmpty) {
      return _buildEmptyChart(context);
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(),
                centerSpaceRadius: 60,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
            ),
          ),

          const SizedBox(height: 16),

          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Center(child: Text('No spending data available')),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = spendingData.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (total == 0) return [];

    final sortedEntries = spendingData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / total * 100);

      return PieChartSectionData(
        color: AppColors.getChartColor(index),
        value: amount,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 80,
        titleStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    final sortedEntries = spendingData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: sortedEntries.take(6).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value.key;
        final amount = entry.value.value;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.getChartColor(index),
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 8),

            Text(category, style: AppTextStyles.caption),

            const SizedBox(width: 4),

            Text(
              '\$${amount.toStringAsFixed(0)}',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
