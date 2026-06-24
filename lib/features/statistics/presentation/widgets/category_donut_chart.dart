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
  bool _otherExpanded = false;

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
              children: [
                for (var index = 0; index < widget.breakdown.length; index++)
                  ..._buildLegendEntry(index),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildLegendEntry(int index) {
    final item = widget.breakdown[index];
    final color = _colorForIndex(index, item);
    final isHighlighted = index == _highlightedIndex;
    final expandable = item.hasChildren;

    final row = _legendRow(
      color: color,
      name: item.categoryName,
      amount: item.amount,
      share: item.share,
      isHighlighted: isHighlighted,
      trailing: expandable
          ? Padding(
              padding: const EdgeInsets.only(left: 4),
              child: AnimatedRotation(
                turns: _otherExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                child: const Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
              ),
            )
          : null,
    );

    return [
      if (expandable)
        InkWell(
          onTap: () => setState(() => _otherExpanded = !_otherExpanded),
          borderRadius: BorderRadius.circular(8),
          child: row,
        )
      else
        row,
      if (expandable)
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _otherExpanded
              ? _buildChildrenCard(index, item.children)
              : const SizedBox(width: double.infinity),
        ),
    ];
  }

  Widget _buildChildrenCard(int otherIndex, List<CategoryBreakdown> children) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'В составе «Другое»',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          for (var i = 0; i < children.length; i++)
            _legendRow(
              color: ChartPalette.colorAt(otherIndex + i),
              name: children[i].categoryName,
              amount: children[i].amount,
              share: children[i].share,
              isHighlighted: false,
              dense: true,
              badgeColor: AppColors.surface,
            ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required Color color,
    required String name,
    required double amount,
    required double share,
    required bool isHighlighted,
    Widget? trailing,
    bool dense = false,
    Color badgeColor = AppColors.surfaceAlt,
  }) {
    final dotSize = dense ? 10.0 : 12.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 4 : 5),
      child: Row(
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: dense ? 13 : 14,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMoneyAbs(amount),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              fontSize: dense ? 12.5 : 13.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${(share * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
