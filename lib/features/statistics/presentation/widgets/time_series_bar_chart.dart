import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/period_bucket.dart';
import '../../domain/entities/period_type.dart';

class TimeSeriesBarChart extends StatelessWidget {
  const TimeSeriesBarChart({
    super.key,
    required this.buckets,
    required this.periodType,
  });

  final List<PeriodBucket> buckets;
  final PeriodType periodType;

  static const _months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  String _bucketLabel(PeriodBucket bucket) {
    final start = bucket.range.start;
    final granularity = periodType == PeriodType.allTime
        ? PeriodType.year
        : periodType;
    switch (granularity) {
      case PeriodType.day:
        return '${start.day}\n${_months[start.month - 1]}';
      case PeriodType.week:
        final lastDay = bucket.range.end.subtract(const Duration(days: 1));
        return '${start.day}–${lastDay.day}\n${_months[start.month - 1]}';
      case PeriodType.month:
        return '${_months[start.month - 1]}\n${start.year}';
      case PeriodType.year:
        return '${start.year}';
      case PeriodType.allTime:
        return '${start.year}';
    }
  }

  String _formatMoney(double value) => formatMoneyAbs(value);

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outline),
        ),
        child: const SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'Нет данных',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
        ),
      );
    }

    final maxValue = buckets
        .map((b) => b.income > b.expense ? b.income : b.expense)
        .fold<double>(0, (max, v) => v > max ? v : max);
    final yMax = maxValue == 0 ? 10.0 : maxValue * 1.15;

    final totalIncome = buckets.fold<double>(0, (s, b) => s + b.income);
    final totalExpense = buckets.fold<double>(0, (s, b) => s + b.expense);
    final totalNet = totalIncome - totalExpense;

    const groupWidth = 64.0;
    final chartWidth = groupWidth * buckets.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Доходы и расходы',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _LegendDot(color: AppColors.income, label: 'Доход'),
                _LegendDot(color: AppColors.expense, label: 'Расход'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: Row(
                children: [
                  SizedBox(width: 48, child: _YAxisLabels(maxValue: yMax)),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: SizedBox(
                        width: chartWidth < 200 ? 200 : chartWidth,
                        child: BarChart(
                          BarChartData(
                            maxY: yMax,
                            minY: 0,
                            alignment: BarChartAlignment.spaceAround,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: yMax / 4,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.2),
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
                                  reservedSize: 36,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= buckets.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _bucketLabel(buckets[index]),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => Colors.black87,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final bucket = buckets[group.x];
                                  final isIncome = rodIndex == 0;
                                  final value = isIncome
                                      ? bucket.income
                                      : bucket.expense;
                                  final label = isIncome ? 'Доход' : 'Расход';
                                  return BarTooltipItem(
                                    '$label\n${_formatMoney(value)}\nИтог: ${_formatMoney(bucket.net)}',
                                    const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            barGroups: List.generate(buckets.length, (i) {
                              final b = buckets[i];
                              return BarChartGroupData(
                                x: i,
                                barsSpace: 4,
                                barRods: [
                                  BarChartRodData(
                                    toY: b.income,
                                    color: AppColors.income,
                                    width: 12,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(2),
                                    ),
                                  ),
                                  BarChartRodData(
                                    toY: b.expense,
                                    color: AppColors.expense,
                                    width: 12,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(2),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryLine(
                    label: 'Всего доходов',
                    value: _formatMoney(totalIncome),
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _SummaryLine(
                    label: 'Всего расходов',
                    value: _formatMoney(totalExpense),
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _SummaryLine(
                    label: 'Итог',
                    value: _formatMoney(totalNet),
                    color: totalNet < 0 ? AppColors.expense : AppColors.income,
                    bold: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels({required this.maxValue});

  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final steps = [
      maxValue,
      maxValue * 0.75,
      maxValue * 0.5,
      maxValue * 0.25,
      0.0,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 36, top: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Text(
              steps[i].toStringAsFixed(0),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            if (i != steps.length - 1) const Spacer(),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
