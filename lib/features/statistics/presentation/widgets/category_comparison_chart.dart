import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/category_breakdown.dart';
import 'category_comparison_legend.dart';
import 'category_donut_plot.dart';
import 'chart_palette.dart';
import 'statistics_number_format.dart';

class CategoryComparisonChart extends StatefulWidget {
  const CategoryComparisonChart({
    super.key,
    required this.title,
    required this.total,
    required this.breakdown,
    required this.accentColor,
    required this.icon,
    required this.averageTotal,
    required this.averageBreakdown,
    required this.periodLabel,
    required this.averageLabel,
    required this.matchesElapsedDays,
  });

  final String title;
  final double total;
  final List<CategoryBreakdown> breakdown;
  final Color accentColor;
  final IconData icon;
  final double? averageTotal;
  final List<CategoryBreakdown> averageBreakdown;
  final String periodLabel;
  final String averageLabel;
  final bool matchesElapsedDays;

  @override
  State<CategoryComparisonChart> createState() =>
      _CategoryComparisonChartState();
}

class _CategoryComparisonChartState extends State<CategoryComparisonChart> {
  int? _selectedIndex;
  int? _hoveredIndex;
  bool _showAmounts = false;
  bool _otherExpanded = false;
  late List<CategoryBreakdown> _current;
  late List<CategoryBreakdown> _average;

  int? get _highlightedIndex => _hoveredIndex ?? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _alignCategories();
  }

  @override
  void didUpdateWidget(covariant CategoryComparisonChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.breakdown != widget.breakdown ||
        oldWidget.averageBreakdown != widget.averageBreakdown ||
        oldWidget.periodLabel != widget.periodLabel) {
      _selectedIndex = null;
      _hoveredIndex = null;
      _otherExpanded = false;
      _alignCategories();
    }
  }

  static CategoryBreakdown _zero(CategoryBreakdown item) => CategoryBreakdown(
    categoryId: item.categoryId,
    categoryName: item.categoryName,
    amount: 0,
    share: 0,
    children: item.children.map(_zero).toList(),
  );

  void _alignCategories() {
    final currentById = {
      for (final item in widget.breakdown) item.categoryId: item,
    };
    final averageById = {
      for (final item in widget.averageBreakdown) item.categoryId: item,
    };
    final ids = {...currentById.keys, ...averageById.keys};
    _current = [
      for (final id in ids) currentById[id] ?? _zero(averageById[id]!),
    ];
    _average = [
      for (final id in ids) averageById[id] ?? _zero(currentById[id]!),
    ];
  }

  Color _colorAt(int index) => _current[index].categoryId == null
      ? ChartPalette.other
      : ChartPalette.colorAt(index);

  void _select(int index) {
    setState(() {
      _hoveredIndex = null;
      _selectedIndex = _selectedIndex == index ? null : index;
      if (_current[index].hasChildren) {
        _otherExpanded = _selectedIndex == index;
      }
    });
  }

  void _onTouch(FlTouchEvent event, PieTouchResponse? response) {
    final touched = response?.touchedSection?.touchedSectionIndex;
    final index = touched != null && touched >= 0 && touched < _current.length
        ? touched
        : null;
    if (event is FlTapUpEvent && index != null) {
      _select(index);
    } else if (event is FlPointerHoverEvent) {
      if (_hoveredIndex != index) setState(() => _hoveredIndex = index);
    } else if (event is FlPointerExitEvent && _hoveredIndex != null) {
      setState(() => _hoveredIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCharts(),
          if (widget.averageTotal != null) ...[
            const SizedBox(height: 12),
            _buildDifference(),
          ],
          if (_current.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildLegend(),
          ],
          if (_selectedIndex != null) _buildSelectionDetail(),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    final current = CategoryDonutPlot(
      label: widget.periodLabel,
      subtitle: widget.matchesElapsedDays
          ? 'Неполный период'
          : 'Выбранный период',
      total: widget.total,
      breakdown: _current,
      colorAt: _colorAt,
      highlightedIndex: _highlightedIndex,
      onTouch: _onTouch,
    );
    final average = CategoryDonutPlot(
      label: widget.averageLabel,
      subtitle: 'За всю историю',
      total: widget.averageTotal,
      breakdown: _average,
      colorAt: _colorAt,
      highlightedIndex: _highlightedIndex,
      onTouch: _onTouch,
      isAverage: true,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 230 ||
            MediaQuery.textScalerOf(context).scale(12) > 17) {
          return Column(
            children: [current, const SizedBox(height: 20), average],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: current),
            const SizedBox(width: 12),
            Expanded(child: average),
          ],
        );
      },
    );
  }

  Widget _buildDifference() {
    final average = widget.averageTotal!;
    final difference = widget.total - average;
    final equal = difference.abs() < .005;
    final percent = average > 0
        ? '${formatStatisticNumber(difference.abs() / average * 100)}% '
              '${difference > 0 ? 'выше' : 'ниже'} среднего'
        : 'в среднем операций не было';
    final label = equal
        ? 'На уровне среднего'
        : '${formatCompactStatisticMoney(difference.abs())} '
              '${difference > 0 ? 'больше' : 'меньше'} · $percent';
    return Semantics(
      label: equal ? label : 'Разница ${formatMoney(difference)}. $percent',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              equal
                  ? Icons.drag_handle_rounded
                  : difference > 0
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            const Text(
              'Категории',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              padding: const EdgeInsets.all(3),
              child: Wrap(
                children: [
                  _modeButton('Доли', false),
                  _modeButton('Суммы', true),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      CategoryComparisonLegend(
        breakdown: _current,
        averageBreakdown: _average,
        showComparison: true,
        hasAverage: widget.averageTotal != null,
        showAmounts: _showAmounts,
        selectedIndex: _highlightedIndex,
        otherExpanded: _otherExpanded,
        colorAt: _colorAt,
        onSelect: _select,
      ),
    ],
  );

  Widget _modeButton(String label, bool amountMode) {
    final selected = _showAmounts == amountMode;
    return Semantics(
      selected: selected,
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          backgroundColor: selected ? AppColors.surface : Colors.transparent,
          foregroundColor: selected
              ? AppColors.textPrimary
              : AppColors.textSecondary,
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => setState(() => _showAmounts = amountMode),
        child: Text(label),
      ),
    );
  }

  Widget _buildSelectionDetail() {
    final item = _current[_selectedIndex!];
    final average = _average[_selectedIndex!];
    final text = StringBuffer(
      '${item.categoryName}\nЗа период: ${formatMoneyAbs(item.amount)}',
    );
    if (widget.averageTotal != null) {
      text
        ..write('\nВ среднем: ${formatMoneyAbs(average.amount)}')
        ..write('\nРазница: ${formatMoney(item.amount - average.amount)}');
    }
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.brandContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          text.toString().replaceAll(' ', ' '),
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
