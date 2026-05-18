import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

  String _formatMoney(double value) {
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return const Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(height: 220, child: Center(child: Text('Нет данных'))),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Доходы и расходы',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _LegendDot(color: Colors.green, label: 'Доход'),
                _LegendDot(color: Colors.red, label: 'Расход'),
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
                                    color: Colors.green,
                                    width: 12,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(2),
                                    ),
                                  ),
                                  BarChartRodData(
                                    toY: b.expense,
                                    color: Colors.red,
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
                    color: Colors.green,
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
                    color: Colors.red,
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
                    color: totalNet < 0 ? Colors.red : Colors.green,
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
