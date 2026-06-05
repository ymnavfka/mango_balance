import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/budget_period.dart';
import '../../domain/entities/budget_progress.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.progress,
    required this.onTap,
  });

  final BudgetProgress progress;
  final VoidCallback onTap;

  Color _statusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.under:
        return AppColors.income;
      case BudgetStatus.warning:
        return AppColors.warning;
      case BudgetStatus.over:
        return AppColors.expense;
    }
  }

  String _categoriesLabel() {
    if (progress.budget.allCategories) return 'Все категории';
    if (progress.categoryNames.isEmpty) return 'Нет категорий';
    if (progress.categoryNames.length <= 3) {
      return progress.categoryNames.join(', ');
    }
    return '${progress.categoryNames.take(2).join(', ')} '
        '+${progress.categoryNames.length - 2}';
  }

  String _pluralDays(int days) {
    final mod100 = days % 100;
    final mod10 = days % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }

  String _daysLabel() {
    final days = progress.daysRemaining;
    if (days == 0) return 'Последний день периода';
    return 'Осталось $days ${_pluralDays(days)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(progress.status);
    final fill = progress.fillRatio.clamp(0.0, 1.0).toDouble();
    final overshoot = progress.fillRatio > 1.0;
    final percent = (progress.fillRatio * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.outline),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progress.budget.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandContainer,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        progress.budget.period.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _categoriesLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoneyAbs(progress.spent),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '/ ${formatMoneyAbs(progress.limit)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: fill,
                    minHeight: 9,
                    backgroundColor: AppColors.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _daysLabel(),
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      overshoot
                          ? 'Превышение ${formatMoneyAbs(progress.spent - progress.limit)}'
                          : 'Остаток ${formatMoneyAbs(progress.remaining)}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
