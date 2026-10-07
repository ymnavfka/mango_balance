import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../domain/entities/category_averages.dart';
import '../../domain/entities/period_type.dart';
import '../utils/category_comparison_labels.dart';

class CategoryComparisonHeader extends StatefulWidget {
  const CategoryComparisonHeader({
    super.key,
    required this.periodType,
    required this.averages,
  });

  final PeriodType periodType;
  final CategoryAverages? averages;

  @override
  State<CategoryComparisonHeader> createState() =>
      _CategoryComparisonHeaderState();
}

class _CategoryComparisonHeaderState extends State<CategoryComparisonHeader> {
  bool _showMethod = false;

  String get _subtitle {
    final averages = widget.averages;
    if (averages == null || averages.periodCount == 0) {
      return 'Для среднего нужен хотя бы один полный период истории.';
    }
    final count = comparisonPeriodCountLabel(
      widget.periodType,
      averages.periodCount,
    );
    final start = averages.historyStart;
    final end = averages.historyEnd;
    if (start == null || end == null) return count;
    return '${comparisonHistoryLabel(widget.periodType, start, end)} · $count';
  }

  String get _method {
    final partial = widget.averages?.matchesElapsedDays ?? false;
    final days = widget.averages?.elapsedDays;
    final monthDays = days == 1 ? 'первым днём' : 'первыми $days днями';
    final opening = partial
        ? switch (widget.periodType) {
            PeriodType.week =>
              'Сравниваем дни с начала выбранной недели по сегодня '
                  'с теми же днями каждой завершённой недели.',
            PeriodType.month =>
              'Сравниваем дни с начала выбранного месяца по сегодня '
                  'с $monthDays каждого завершённого месяца. '
                  'Если в месяце меньше дней, берём его целиком.',
            PeriodType.year =>
              'Сравниваем дни с начала выбранного года по сегодня '
                  'с теми же календарными датами каждого завершённого года. '
                  'Для 29 февраля в невисокосном году берём 28 февраля.',
            _ => 'Сравниваем суммы за выбранный период со средним.',
          }
        : 'Складываем суммы по каждой категории за все полные периоды '
              'истории и делим на число этих периодов.';
    final calculation = partial
        ? ' Суммы за эти дни складываем и делим на число полных периодов.'
        : '';
    return '$opening$calculation '
        'Периоды без операций тоже учитываем. '
        'Первый период, если история началась не с его первого дня, '
        'и текущий незавершённый период не входят в среднее. '
        'Выбранный завершённый период тоже входит в среднее. '
        'Доля категории — её средняя сумма, разделённая на среднюю общую сумму. '
        '«Другое» содержит одинаковые категории в обоих кругах.';
  }

  @override
  Widget build(BuildContext context) {
    final partial = widget.averages?.matchesElapsedDays ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partial
                            ? 'Сравнение за те же дни'
                            : 'Сравнение со средним за всё время',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Semantics(
                expanded: _showMethod,
                child: IconButton(
                  tooltip: _showMethod
                      ? 'Скрыть расчёт среднего'
                      : 'Как считается среднее',
                  onPressed: () => setState(() => _showMethod = !_showMethod),
                  style: IconButton.styleFrom(
                    foregroundColor: _showMethod
                        ? AppColors.brand
                        : AppColors.textSecondary,
                    backgroundColor: _showMethod
                        ? AppColors.brandContainer
                        : Colors.transparent,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                ),
              ),
            ],
          ),
          if (_showMethod)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(
                _method,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
