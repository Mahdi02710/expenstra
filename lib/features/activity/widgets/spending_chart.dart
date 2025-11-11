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

    // Use LayoutBuilder to make the chart responsive and avoid fixed-height
    return LayoutBuilder(
      builder: (context, constraints) {
        // Limit height so the chart doesn't take too much space on narrow screens
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final containerHeight = math.min(300, availableWidth * 0.75).toDouble();
        final pieRadius = math.max(40, containerHeight * 0.26).toDouble();

        return Container(
          height: containerHeight,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              // Constrain PieChart using an AspectRatio so it stays circular
              AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(pieRadius),
                    centerSpaceRadius: pieRadius * 0.75,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Legend can wrap under the chart — using Wrap inside ensures it
              // will flow to multiple lines rather than overlap neighboring widgets.
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    // Keep empty chart responsive too
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

  List<PieChartSectionData> _buildPieChartSections([double? radius]) {
    final total = spendingData.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (total == 0) return [];

    final sortedEntries = spendingData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final amount = entry.value.value;
      final percentage = (amount / total * 100);

      return PieChartSectionData(
        color: AppColors.getChartColor(index),
        value: amount,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: radius?.clamp(40, 120) ?? 80,
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
