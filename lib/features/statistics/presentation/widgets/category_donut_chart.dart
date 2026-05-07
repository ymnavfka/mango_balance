import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/category_breakdown.dart';
import 'chart_palette.dart';

class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({
    super.key,
    required this.title,
    required this.total,
    required this.breakdown,
    required this.accentColor,
  });

  final String title;
  final double total;
  final List<CategoryBreakdown> breakdown;
  final Color accentColor;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? _highlightedIndex;

  String _formatMoney(double value) {
    return value.toStringAsFixed(2);
  }

  Color _colorForIndex(int index, CategoryBreakdown item) {
    if (item.categoryId == null) {
      return ChartPalette.other;
    }
    return ChartPalette.colorAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.breakdown.isEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.accentColor,
              ),
            ),
            const SizedBox(height: 16),
            if (isEmpty)
              const SizedBox(
                height: 220,
                child: Center(child: Text('No data for this period')),
              )
            else
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
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
                        sections: List.generate(widget.breakdown.length, (
                          index,
                        ) {
                          final item = widget.breakdown[index];
                          final isHighlighted = index == _highlightedIndex;
                          return PieChartSectionData(
                            value: item.amount,
                            color: _colorForIndex(index, item),
                            radius: isHighlighted ? 56 : 48,
                            showTitle: false,
                          );
                        }),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatMoney(widget.total),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (!isEmpty) const SizedBox(height: 16),
            if (!isEmpty)
              Column(
                children: List.generate(widget.breakdown.length, (index) {
                  final item = widget.breakdown[index];
                  final color = _colorForIndex(index, item);
                  final isHighlighted = index == _highlightedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.categoryName,
                            style: TextStyle(
                              fontWeight: isHighlighted
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          '${_formatMoney(item.amount)}  '
                          '(${(item.share * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontWeight: isHighlighted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
