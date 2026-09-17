import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/period_bucket.dart';
import '../../domain/entities/period_type.dart';

class TimeSeriesBarChart extends StatefulWidget {
  const TimeSeriesBarChart({
    super.key,
    required this.buckets,
    required this.periodType,
  });

  final List<PeriodBucket> buckets;
  final PeriodType periodType;

  @override
  State<TimeSeriesBarChart> createState() => _TimeSeriesBarChartState();
}

class _TimeSeriesBarChartState extends State<TimeSeriesBarChart> {
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

  // Ширина одной группы столбцов и колонки подписей оси Y.
  static const double _groupWidth = 64;
  static const double _yAxisWidth = 48;
  static const double _minContentWidth = 200;

  late final ScrollController _scrollController;

  // Геометрия последней раскладки — нужна слушателю прокрутки, чтобы понять,
  // какие столбцы сейчас видны, без повторного измерения вьюпорта.
  double _contentWidth = 0;
  double _viewportWidth = 0;
  double _yMax = 10;

  // Средние доход/расход за период за всё время (для группы «Среднее»).
  double _avgIncome = 0;
  double _avgExpense = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final newYMax = _yMaxFor(_visibleMaxValue(_scrollController.offset));
    if ((newYMax - _yMax).abs() > 1e-6) {
      // Видимый максимум изменился — пересчитываем шкалу и подписи оси Y.
      setState(() {});
    }
  }

  double _yMaxFor(double maxValue) => maxValue <= 0 ? 10.0 : maxValue * 1.15;

  // Число групп столбцов: периоды + завершающая группа «Среднее».
  int get _groupCount => widget.buckets.length + 1;

  // Доход/расход для группы по индексу. Последний индекс — группа «Среднее».
  ({double income, double expense}) _groupValues(int index) {
    final buckets = widget.buckets;
    if (index >= buckets.length) {
      return (income: _avgIncome, expense: _avgExpense);
    }
    return (income: buckets[index].income, expense: buckets[index].expense);
  }

  double _groupMax(int index) {
    final v = _groupValues(index);
    return v.income > v.expense ? v.income : v.expense;
  }

  // Максимум среди столбцов, чьи ячейки пересекают видимую область прокрутки.
  // Прокрутка идёт в reverse: смещение 0 показывает правый край контента.
  double _visibleMaxValue(double offset) {
    if (widget.buckets.isEmpty || _contentWidth <= 0) return 0;

    final perGroup = _contentWidth / _groupCount;
    final visibleRight = _contentWidth - offset;
    final visibleLeft = visibleRight - _viewportWidth;

    double maxVisible = 0;
    var found = false;
    for (var i = 0; i < _groupCount; i++) {
      final cellLeft = i * perGroup;
      final cellRight = cellLeft + perGroup;
      if (cellRight > visibleLeft && cellLeft < visibleRight) {
        final v = _groupMax(i);
        if (v > maxVisible) maxVisible = v;
        found = true;
      }
    }
    if (!found) {
      for (var i = 0; i < _groupCount; i++) {
        final v = _groupMax(i);
        if (v > maxVisible) maxVisible = v;
      }
    }
    return maxVisible;
  }

  // Слово для подписи периода в тултипе «Среднее за …».
  String _avgPeriodWord() {
    final granularity = widget.periodType == PeriodType.allTime
        ? PeriodType.year
        : widget.periodType;
    switch (granularity) {
      case PeriodType.day:
        return 'день';
      case PeriodType.week:
        return 'неделю';
      case PeriodType.month:
        return 'месяц';
      case PeriodType.year:
        return 'год';
      case PeriodType.allTime:
        return 'год';
    }
  }

  String _bucketLabel(PeriodBucket bucket) {
    final start = bucket.range.start;
    final granularity = widget.periodType == PeriodType.allTime
        ? PeriodType.year
        : widget.periodType;
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

  // Знаковый формат: доходы и расходы здесь всегда ≥ 0, а «Итог» (net)
  // может быть отрицательным — для него важно показать минус.
  String _formatMoney(double value) => formatMoney(value);

  @override
  Widget build(BuildContext context) {
    final buckets = widget.buckets;
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

    final totalIncome = buckets.fold<double>(0, (s, b) => s + b.income);
    final totalExpense = buckets.fold<double>(0, (s, b) => s + b.expense);
    final totalNet = totalIncome - totalExpense;

    // Среднее за период за всё время — по всем периодам, включая пустые.
    _avgIncome = totalIncome / buckets.length;
    _avgExpense = totalExpense / buckets.length;

    final chartWidth = _groupWidth * _groupCount;
    final contentWidth = chartWidth < _minContentWidth
        ? _minContentWidth
        : chartWidth;

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
            const SizedBox(height: 6),
            Text(
              'Крайняя группа «Среднее» — средние доход и расход '
              'за ${_avgPeriodWord()} за всё время.',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Шкала Y подстраивается под столбцы, попадающие в видимую
                  // область прокрутки, а не под все сразу — иначе одиночный
                  // выброс за экраном сплющивал бы все видимые столбцы.
                  _contentWidth = contentWidth;
                  _viewportWidth = (constraints.maxWidth - _yAxisWidth).clamp(
                    0.0,
                    double.infinity,
                  );
                  final offset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0.0;
                  final yMax = _yMaxFor(_visibleMaxValue(offset));
                  _yMax = yMax;
                  return Row(
                    children: [
                      SizedBox(
                        width: _yAxisWidth,
                        child: _YAxisLabels(maxValue: yMax),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: SizedBox(
                            width: contentWidth,
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
                                        if (index < 0 ||
                                            index > buckets.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final isAvg = index == buckets.length;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            isAvg
                                                ? 'Среднее'
                                                : _bucketLabel(buckets[index]),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isAvg
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color: isAvg
                                                  ? AppColors.textSecondary
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    fitInsideVertically: true,
                                    fitInsideHorizontally: true,
                                    getTooltipColor: (_) => Colors.black87,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                          final isIncome = rodIndex == 0;
                                          final label = isIncome
                                              ? 'Доход'
                                              : 'Расход';
                                          if (group.x >= buckets.length) {
                                            final value = isIncome
                                                ? _avgIncome
                                                : _avgExpense;
                                            final avgNet =
                                                _avgIncome - _avgExpense;
                                            return BarTooltipItem(
                                              'Среднее за ${_avgPeriodWord()}\n'
                                              '$label: ${_formatMoney(value)}\n'
                                              'Итог: ${_formatMoney(avgNet)}',
                                              const TextStyle(
                                                color: Colors.white,
                                              ),
                                            );
                                          }
                                          final bucket = buckets[group.x];
                                          final value = isIncome
                                              ? bucket.income
                                              : bucket.expense;
                                          return BarTooltipItem(
                                            '$label\n${_formatMoney(value)}\nИтог: ${_formatMoney(bucket.net)}',
                                            const TextStyle(
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                  ),
                                ),
                                barGroups: List.generate(_groupCount, (i) {
                                  final values = _groupValues(i);
                                  final isAvg = i >= buckets.length;
                                  // Группа «Среднее» — те же цвета, но светлее,
                                  // чтобы читалась как справочная, а не период.
                                  final incomeColor = isAvg
                                      ? AppColors.income.withValues(alpha: 0.45)
                                      : AppColors.income;
                                  final expenseColor = isAvg
                                      ? AppColors.expense.withValues(
                                          alpha: 0.45,
                                        )
                                      : AppColors.expense;
                                  return BarChartGroupData(
                                    x: i,
                                    barsSpace: 4,
                                    barRods: [
                                      BarChartRodData(
                                        toY: values.income,
                                        color: incomeColor,
                                        width: 12,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(2),
                                            ),
                                      ),
                                      BarChartRodData(
                                        toY: values.expense,
                                        color: expenseColor,
                                        width: 12,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(2),
                                            ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 150),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
