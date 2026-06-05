import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/category_breakdown.dart';
import 'chart_palette.dart';

class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({
    super.key,
    required this.title,
    required this.total,
    required this.breakdown,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final double total;
  final List<CategoryBreakdown> breakdown;
  final Color accentColor;
  final IconData icon;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? _highlightedIndex;

  Color _colorForIndex(int index, CategoryBreakdown item) {
    if (item.categoryId == null) {
      return ChartPalette.other;
    }
    return ChartPalette.colorAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.breakdown.isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
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
                  color: widget.accentColor.withValues(alpha: 0.12),
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
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Нет данных за этот период',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            )
          else
            SizedBox(
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 64,
                      startDegreeOffset: -90,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _highlightedIndex = null;
                              return;
                            }
                            _highlightedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: List.generate(widget.breakdown.length, (index) {
                        final item = widget.breakdown[index];
                        final isHighlighted = index == _highlightedIndex;
                        return PieChartSectionData(
                          value: item.amount,
                          color: _colorForIndex(index, item),
                          radius: isHighlighted ? 26 : 20,
                          showTitle: false,
                        );
                      }),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Всего',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatMoneyAbs(widget.total),
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: widget.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (!isEmpty) ...[
            const SizedBox(height: 16),
            Column(
              children: List.generate(widget.breakdown.length, (index) {
                final item = widget.breakdown[index];
                final color = _colorForIndex(index, item);
                final isHighlighted = index == _highlightedIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: isHighlighted
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatMoneyAbs(item.amount),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: isHighlighted
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(item.share * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
