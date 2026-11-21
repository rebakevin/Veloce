import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/entities/finance_transaction.dart';
import '../../domain/enums/finance_period.dart';

/// Paired bar chart displaying Earned and Losses over time (fl_chart).
class FinanceChart extends StatelessWidget {
  const FinanceChart({
    required this.transactions,
    required this.period,
    required this.now,
    super.key,
  });

  final List<FinanceTransaction> transactions;
  final FinancePeriod period;

  /// Reference date of the period, from the injected clock.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isMonth = period == FinancePeriod.thisMonth;
    final int bucketCount = isMonth
        ? DateTime(now.year, now.month + 1, 0).day
        : 12;

    final earnedBuckets = List<int>.filled(bucketCount + 1, 0);
    final lossBuckets = List<int>.filled(bucketCount + 1, 0);

    for (final tx in transactions) {
      final bucket = isMonth ? tx.date.day : tx.date.month;
      if (bucket >= 1 && bucket <= bucketCount) {
        if (tx.type == FinanceEntryType.earned) {
          earnedBuckets[bucket] += tx.amount;
        } else {
          lossBuckets[bucket] += tx.amount;
        }
      }
    }

    double maxVal = 0;
    for (int i = 1; i <= bucketCount; i++) {
      maxVal = max(
        maxVal,
        max(earnedBuckets[i].toDouble(), lossBuckets[i].toDouble()),
      );
    }
    if (maxVal == 0) maxVal = 100000;

    final barGroups = <BarChartGroupData>[];
    for (int i = 1; i <= bucketCount; i++) {
      final earned = earnedBuckets[i].toDouble();
      final loss = lossBuckets[i].toDouble();

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: earned,
              color: colors.brand,
              width: isMonth ? 4 : 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
            BarChartRodData(
              toY: loss,
              color: colors.danger,
              width: isMonth ? 4 : 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _LegendItem(color: colors.brand, label: 'Earned'),
            const SizedBox(width: AppSpacing.md),
            _LegendItem(color: colors.danger, label: 'Losses'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxVal * 1.15,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxVal / 3,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colors.line.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (isMonth) {
                        if (index == 1 ||
                            index % 5 == 0 ||
                            index == bucketCount) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$index',
                              style: AppTextStyles.caption.copyWith(
                                color: colors.muted,
                              ),
                            ),
                          );
                        }
                      } else {
                        const months = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                          'Jul',
                          'Aug',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dec',
                        ];
                        if (index >= 1 && index <= 12) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              months[index - 1],
                              style: AppTextStyles.caption.copyWith(
                                color: colors.muted,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isEarned = rodIndex == 0;
                    final type = isEarned ? 'Earned' : 'Loss';
                    return BarTooltipItem(
                      '$type: ${Formatters.rwf(rod.toY.toInt())}',
                      TextStyle(
                        color: colors.surface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.caption.copyWith(color: colors.muted)),
      ],
    );
  }
}
