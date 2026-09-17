import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/net_worth_point.dart';

/// График изменения капитала (накопленного общего баланса) за всё время.
///
/// Участки линии выше нуля рисуются зелёным, ниже нуля — красным; области
/// между линией и нулём подкрашиваются соответствующим цветом.
class NetWorthLineChart extends StatelessWidget {
  const NetWorthLineChart({super.key, required this.points});

  final List<NetWorthPoint> points;

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

  DateTime _dateForX(double x) =>
      points.first.date.add(Duration(days: x.round()));

  String _axisDateLabel(DateTime date, int spanDays) {
    if (spanDays > 700) {
      return '${date.year}';
    }
    if (spanDays > 120) {
      return '${_months[date.month - 1]} ${date.year % 100}';
    }
    return '${date.day} ${_months[date.month - 1]}';
  }

  String _fullDateLabel(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  String _compactMoney(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '−' : '';
    if (abs >= 1e9) return '$sign${_trimmed(abs / 1e9)} млрд';
    if (abs >= 1e6) return '$sign${_trimmed(abs / 1e6)} млн';
    if (abs >= 1e3) return '$sign${_trimmed(abs / 1e3)} тыс.';
    return '$sign${abs.toStringAsFixed(0)}';
  }

  String _trimmed(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0')
        ? fixed.substring(0, fixed.length - 2)
        : fixed.replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox.shrink();
    }

    final firstDay = points.first.date;
    final spots = points
        .map(
          (p) =>
              FlSpot(p.date.difference(firstDay).inDays.toDouble(), p.balance),
        )
        .toList();

    final minBalance = points.map((p) => p.balance).reduce(math.min);
    final maxBalance = points.map((p) => p.balance).reduce(math.max);
    var padding = (maxBalance - minBalance) * 0.12;
    if (padding == 0) {
      padding = maxBalance.abs() * 0.12 + 10;
    }
    // Первая точка ряда нулевая, поэтому ноль всегда внутри диапазона.
    final minY = minBalance - padding;
    final maxY = maxBalance + padding;

    final maxX = spots.last.x;
    final spanDays = maxX.round();
    final bottomInterval = math.max(1.0, maxX / 4);
    // fl_chart накладывает градиент линии на bounding box самих точек
    // (minBalance..maxBalance), а не на диапазон осей с паддингом. Поэтому
    // долю нуля для границы цвета считаем именно от диапазона значений —
    // иначе граница «зелёный/красный» не совпадёт с нулём (заметно на телефоне).
    final dataRange = maxBalance - minBalance;
    final zeroFraction = dataRange == 0
        ? 0.0
        : ((0 - minBalance) / dataRange).clamp(0.0, 1.0);

    final current = points.last.balance;

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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Капитал',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  formatMoney(current),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amount(current),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Изменение общего баланса за всё время',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: AppColors.textTertiary.withValues(alpha: 0.6),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: (maxY - minY) / 4,
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(
                            _compactMoney(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: bottomInterval,
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6,
                          child: Text(
                            _axisDateLabel(_dateForX(value), spanDays),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (barData, spotIndexes) =>
                        spotIndexes.map((index) {
                          final spot = barData.spots[index];
                          final color = spot.y >= 0
                              ? AppColors.income
                              : AppColors.expense;
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: color.withValues(alpha: 0.45),
                              strokeWidth: 2,
                            ),
                            FlDotData(
                              getDotPainter: (s, percent, bar, i) =>
                                  FlDotCirclePainter(
                                    radius: 5,
                                    color: color,
                                    strokeColor: Colors.white,
                                    strokeWidth: 2,
                                  ),
                            ),
                          );
                        }).toList(),
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black87,
                      getTooltipItems: (touchedSpots) => touchedSpots.map((
                        spot,
                      ) {
                        final color = spot.y >= 0
                            ? AppColors.income
                            : AppColors.expense;
                        return LineTooltipItem(
                          '${_fullDateLabel(_dateForX(spot.x))}\n',
                          const TextStyle(color: Colors.white, fontSize: 12),
                          children: [
                            TextSpan(
                              text: formatMoney(spot.y),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: const [
                          AppColors.expense,
                          AppColors.expense,
                          AppColors.income,
                          AppColors.income,
                        ],
                        stops: [0, zeroFraction, zeroFraction, 1],
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        applyCutOffY: true,
                        cutOffY: 0,
                        color: AppColors.income.withValues(alpha: 0.12),
                      ),
                      aboveBarData: BarAreaData(
                        show: true,
                        applyCutOffY: true,
                        cutOffY: 0,
                        color: AppColors.expense.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
