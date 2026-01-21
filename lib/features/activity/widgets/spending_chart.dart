import 'dart:math' as math;
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

    final normalizedData = _normalizeEntries();
    if (normalizedData.isEmpty) {
      return _buildEmptyChart(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        const edgePadding = 24.0;
        final innerWidth = math.max(0.0, availableWidth - (edgePadding * 2));
        final chartSize = math.min(200, innerWidth * 0.85).toDouble();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(edgePadding),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 25),
              // Chart area
              Center(
                child: SizedBox(
                  height: chartSize,
                  width: chartSize,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(normalizedData),
                      centerSpaceRadius: chartSize * 0.35,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Legend (auto-wraps)
              _buildLegend(normalizedData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = math.min(300, width * 0.75).toDouble();
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Center(child: Text('No spending data available')),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<MapEntry<String, double>> entries,
  ) {
    final total = entries.fold<double>(0, (sum, v) => sum + v.value);
    if (total == 0) return [];

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final label = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / total) * 100;

      return PieChartSectionData(
        color: AppColors.getChartColor(index),
        value: amount,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 70,
        titleStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(List<MapEntry<String, double>> entries) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: entries.asMap().entries.map((entry) {
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

  List<MapEntry<String, double>> _normalizeEntries() {
    final sorted = spendingData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.length <= 5) {
      return sorted;
    }
    final top = sorted.take(5).toList();
    final otherTotal = sorted
        .skip(5)
        .fold<double>(0, (sum, entry) => sum + entry.value);
    if (otherTotal > 0) {
      top.add(MapEntry('Other', otherTotal));
    }
    return top;
  }
}
