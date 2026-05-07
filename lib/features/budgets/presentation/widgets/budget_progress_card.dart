import 'package:flutter/material.dart';

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
        return Colors.green;
      case BudgetStatus.warning:
        return Colors.orange;
      case BudgetStatus.over:
        return Colors.red;
    }
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(2);
  }

  String _categoriesLabel() {
    if (progress.budget.allCategories) return 'All categories';
    if (progress.categoryNames.isEmpty) return 'No categories';
    if (progress.categoryNames.length <= 3) {
      return progress.categoryNames.join(', ');
    }
    return '${progress.categoryNames.take(2).join(', ')} +${progress.categoryNames.length - 2}';
  }

  String _daysLabel() {
    final days = progress.daysRemaining;
    if (days == 0) return 'Last day of period';
    if (days == 1) return '1 day left';
    return '$days days left';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(progress.status);
    final fill = progress.fillRatio.clamp(0.0, 1.0).toDouble();
    final overshoot = progress.fillRatio > 1.0;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      progress.budget.period.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _categoriesLabel(),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fill,
                  minHeight: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatMoney(progress.spent)} / ${_formatMoney(progress.limit)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    overshoot
                        ? 'Over by ${_formatMoney(progress.spent - progress.limit)}'
                        : '${_formatMoney(progress.remaining)} left',
                    style: TextStyle(color: color),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _daysLabel(),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
