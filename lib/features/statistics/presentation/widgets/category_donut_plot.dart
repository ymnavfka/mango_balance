import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/category_breakdown.dart';
import 'statistics_number_format.dart';

/// One distribution in the period/average comparison. Both plots receive the
/// same category order so a selected category stays aligned across the pair.
class CategoryDonutPlot extends StatelessWidget {
  const CategoryDonutPlot({
    super.key,
    required this.label,
    this.subtitle,
    required this.total,
    required this.breakdown,
    required this.colorAt,
    required this.highlightedIndex,
    required this.onTouch,
    this.isAverage = false,
  });

  final String label;
  final String? subtitle;
  final double? total;
  final List<CategoryBreakdown> breakdown;
  final Color Function(int) colorAt;
  final int? highlightedIndex;
  final void Function(FlTouchEvent, PieTouchResponse?) onTouch;
  final bool isAverage;

  static const _labelStyle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
  static const _subtitleStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    height: 1.3,
  );
  static const _totalStyle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 19,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );
  static const _captionStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    height: 1.3,
  );

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final amountText = total == null ? '—' : formatStatisticTotal(total!);
    final emptyText = total == null
        ? 'Пока нет среднего'
        : total == 0
        ? 'Нет операций'
        : null;
    final hasDistribution =
        total != null && total! > 0 && breakdown.any((item) => item.amount > 0);

    return Semantics(
      container: true,
      label: _semanticDescription(),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final diameter = math.min(174.0, constraints.maxWidth);
            final ringWidth = math.min(20.0, diameter * .12);
            final centerRadius = math.max(0.0, diameter / 2 - ringWidth - 2);
            // The widest line is centered in the hole; the shorter captions
            // sit above and below it. Keep a small inset from the ring.
            final centerWidth = math.max(0.0, centerRadius * 2 - 10);
            final totalPainter = TextPainter(
              text: TextSpan(
                text: amountText,
                style: DefaultTextStyle.of(context).style.merge(_totalStyle),
              ),
              textDirection: Directionality.of(context),
              textScaler: scaler,
            )..layout();
            final captionHeight = scaler.scale(11) * 1.3;
            final totalBelow =
                scaler.scale(19) > 19 * 1.36 ||
                totalPainter.width > centerWidth ||
                totalPainter.height + captionHeight * 2 + 4 > centerWidth;
            totalPainter.dispose();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reserve two lines for each header in both plots, even when
                // one label is short, so the rings have a shared top edge.
                SizedBox(
                  height: scaler.scale(13) * 1.3 * 2,
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _labelStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: scaler.scale(11) * 1.3,
                  width: double.infinity,
                  child: Text(
                    subtitle ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _subtitleStyle,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox.square(
                  dimension: diameter,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (hasDistribution)
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: centerRadius,
                            startDegreeOffset: -90,
                            pieTouchData: PieTouchData(touchCallback: onTouch),
                            sections: List.generate(breakdown.length, (index) {
                              final selected =
                                  highlightedIndex == null ||
                                  highlightedIndex == index;
                              return PieChartSectionData(
                                // Keep zeros: fl_chart preserves their indexes
                                // while leaving them out of the painted ring.
                                value: breakdown[index].amount,
                                color: colorAt(
                                  index,
                                ).withValues(alpha: selected ? 1 : .22),
                                radius: ringWidth,
                                showTitle: false,
                              );
                            }),
                          ),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 150),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(2),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: ringWidth,
                                color: AppColors.surfaceAlt,
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      if (!totalBelow)
                        SizedBox(
                          width: centerWidth,
                          child: _amount(amountText),
                        ),
                    ],
                  ),
                ),
                if (totalBelow) ...[
                  const SizedBox(height: 10),
                  _amount(amountText),
                ],
                if (emptyText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: _subtitleStyle,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _amount(String text) {
    final amount = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isAverage ? 'В среднем' : 'Всего',
          textAlign: TextAlign.center,
          style: _captionStyle,
        ),
        const SizedBox(height: 2),
        Text(text, textAlign: TextAlign.center, style: _totalStyle),
        if (total != null)
          const Text(
            'рублей',
            textAlign: TextAlign.center,
            style: _captionStyle,
          ),
      ],
    );
    if (total == null) return amount;
    return Tooltip(
      message: formatMoneyAbs(total!),
      excludeFromSemantics: true,
      child: amount,
    );
  }

  String _semanticDescription() {
    final parts = [label, if (subtitle != null) subtitle!];
    if (total == null) {
      parts.add('Пока нет среднего');
    } else {
      parts.add(
        '${isAverage ? 'В среднем' : 'Всего'} ${formatMoneyAbs(total!)}',
      );
      if (total == 0) parts.add('Нет операций');
      for (final item in breakdown) {
        parts.add(
          '${item.categoryName}: ${formatMoneyAbs(item.amount)}, '
          '${(item.share * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
        );
      }
    }
    return parts.join('. ');
  }
}
