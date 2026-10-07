import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/category_breakdown.dart';
import 'statistics_number_format.dart';

/// One interactive legend shared by the selected and historical charts.
class CategoryComparisonLegend extends StatelessWidget {
  const CategoryComparisonLegend({
    super.key,
    required this.breakdown,
    required this.averageBreakdown,
    required this.showComparison,
    required this.hasAverage,
    required this.showAmounts,
    required this.selectedIndex,
    required this.otherExpanded,
    required this.colorAt,
    required this.onSelect,
  });

  final List<CategoryBreakdown> breakdown;
  final List<CategoryBreakdown> averageBreakdown;
  final bool showComparison;
  final bool hasAverage;
  final bool showAmounts;
  final int? selectedIndex;
  final bool otherExpanded;
  final Color Function(int) colorAt;
  final ValueChanged<int> onSelect;

  CategoryBreakdown _averageFor(
    CategoryBreakdown item,
    List<CategoryBreakdown> averages,
  ) {
    for (final average in averages) {
      if (average.categoryId == item.categoryId) return average;
    }
    // A known empty period means zero, while hasAverage handles missing history.
    return CategoryBreakdown(
      categoryId: item.categoryId,
      categoryName: item.categoryName,
      amount: 0,
      share: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            showAmounts ||
            MediaQuery.textScalerOf(context).scale(12) > 15 ||
            constraints.maxWidth < 230;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!stacked) _columnHeadings(),
            for (var index = 0; index < breakdown.length; index++)
              ..._entry(context, index, stacked),
          ],
        );
      },
    );
  }

  Widget _columnHeadings() {
    const style = TextStyle(fontSize: 11, color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 7),
      child: _columns(
        name: const Text('Категория', style: style),
        current: Text(showComparison ? 'Период' : 'Доля', style: style),
        average: const Text('Среднее', style: style),
        delta: const Text('Δ, п.п.', style: style),
      ),
    );
  }

  List<Widget> _entry(BuildContext context, int index, bool stacked) {
    final item = breakdown[index];
    final average = _averageFor(item, averageBreakdown);
    final expandable = item.hasChildren || average.hasChildren;
    final selected = selectedIndex == index;
    final detail = _exactDescription(item, average);
    return [
      Semantics(
        container: true,
        button: true,
        selected: selected,
        expanded: expandable ? otherExpanded : null,
        label: detail,
        onTap: () => onSelect(index),
        child: ExcludeSemantics(
          child: Tooltip(
            message: detail,
            excludeFromSemantics: true,
            child: Material(
              color: selected ? AppColors.brandContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: InkWell(
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: _row(
                      item: item,
                      average: average,
                      color: colorAt(index),
                      stacked: stacked,
                      selected: selected,
                      expandable: expandable,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      if (expandable)
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: otherExpanded
              ? _children(item, average, colorAt(index), stacked)
              : const SizedBox(width: double.infinity),
        ),
    ];
  }

  Widget _children(
    CategoryBreakdown item,
    CategoryBreakdown average,
    Color color,
    bool stacked,
  ) {
    final children = [...item.children];
    for (final child in average.children) {
      if (!children.any((entry) => entry.categoryId == child.categoryId)) {
        children.add(
          CategoryBreakdown(
            categoryId: child.categoryId,
            categoryName: child.categoryName,
            amount: 0,
            share: 0,
          ),
        );
      }
    }
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'В составе «Другое»',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          for (final child in children)
            _childRow(
              child,
              _averageFor(child, average.children),
              color,
              stacked,
            ),
        ],
      ),
    );
  }

  Widget _childRow(
    CategoryBreakdown item,
    CategoryBreakdown average,
    Color color,
    bool stacked,
  ) {
    final detail = _exactDescription(item, average);
    return Semantics(
      label: detail,
      child: ExcludeSemantics(
        child: Tooltip(
          message: detail,
          excludeFromSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _row(
              item: item,
              average: average,
              color: color,
              stacked: stacked,
              selected: false,
              expandable: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _row({
    required CategoryBreakdown item,
    required CategoryBreakdown average,
    required Color color,
    required bool stacked,
    required bool selected,
    required bool expandable,
  }) {
    final current = _value(item);
    final reference = hasAverage ? _value(average) : '—';
    final delta = hasAverage ? _delta(item, average) : '—';
    final name = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.categoryName,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (expandable)
          Icon(
            otherExpanded
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
      ],
    );
    const valueStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    if (!stacked) {
      return _columns(
        name: name,
        current: Text(current, style: valueStyle),
        average: Text(reference, style: valueStyle),
        delta: Text(delta, style: valueStyle),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          name,
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _labeledValue(
                showComparison ? 'Период' : (showAmounts ? 'Сумма' : 'Доля'),
                current,
                constraints.maxWidth,
              ),
              if (showComparison) ...[
                _labeledValue('Среднее', reference, constraints.maxWidth),
                _labeledValue(
                  showAmounts ? 'Разница' : 'Разница, п.п.',
                  delta,
                  constraints.maxWidth,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _columns({
    required Widget name,
    required Widget current,
    required Widget average,
    required Widget delta,
  }) {
    Widget cell(Widget child, double width) => SizedBox(
      width: width,
      child: Align(alignment: Alignment.centerRight, child: child),
    );
    return Row(
      children: [
        Expanded(child: name),
        const SizedBox(width: 4),
        cell(current, 42),
        if (showComparison) ...[
          const SizedBox(width: 4),
          cell(average, 50),
          const SizedBox(width: 4),
          cell(delta, 42),
        ],
      ],
    );
  }

  Widget _labeledValue(String label, String value, double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _value(CategoryBreakdown item) => showAmounts
      ? formatCompactStatisticMoney(item.amount)
      : '${formatStatisticNumber(item.share * 100)}%';

  String _delta(CategoryBreakdown current, CategoryBreakdown average) {
    final value = showAmounts
        ? current.amount - average.amount
        : (current.share - average.share) * 100;
    final rounded = double.parse(value.toStringAsFixed(showAmounts ? 2 : 1));
    if (rounded == 0) return '—';
    final sign = rounded > 0 ? '+' : (rounded < 0 ? '−' : '');
    final amount = showAmounts
        ? formatCompactStatisticMoney(rounded)
        : formatStatisticNumber(rounded.abs());
    return '$sign$amount';
  }

  String _exactDescription(CategoryBreakdown item, CategoryBreakdown average) {
    String exact(CategoryBreakdown entry) =>
        '${formatMoneyAbs(entry.amount)}, '
        '${formatStatisticNumber(entry.share * 100)}%';
    final current = '${item.categoryName}. Период: ${exact(item)}';
    if (!showComparison) return current;
    if (!hasAverage) return '$current. Среднее: недостаточно истории';
    final moneyDelta = item.amount - average.amount;
    final sign = moneyDelta > 0 ? '+' : (moneyDelta < 0 ? '−' : '');
    final points = (item.share - average.share) * 100;
    final pointsRounded = double.parse(points.toStringAsFixed(1));
    final pointsSign = pointsRounded > 0 ? '+' : (pointsRounded < 0 ? '−' : '');
    return '$current. Среднее: ${exact(average)}. '
        'Разница: $sign${formatMoneyAbs(moneyDelta)}, '
        '$pointsSign${formatStatisticNumber(pointsRounded.abs())} п.п.';
  }
}
