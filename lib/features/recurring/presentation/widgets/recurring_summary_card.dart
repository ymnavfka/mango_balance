import 'package:flutter/material.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/money_format.dart';
import '../../domain/entities/recurring_interval.dart';
import '../../domain/entities/recurring_payment.dart';

/// Сводка вверху экрана: суммы активных регулярных платежей, приведённые к
/// дню / неделе / месяцу / году. Расходы и доходы показываются отдельно.
class RecurringSummaryCard extends StatelessWidget {
  const RecurringSummaryCard({super.key, required this.payments});

  final List<RecurringPaymentEntity> payments;

  // Средняя длина единицы интервала в днях.
  static const double _daysInYear = 365.25;
  static const double _daysInMonth = _daysInYear / 12;

  double _unitDays(RecurringInterval unit) {
    switch (unit) {
      case RecurringInterval.day:
        return 1;
      case RecurringInterval.week:
        return 7;
      case RecurringInterval.month:
        return _daysInMonth;
      case RecurringInterval.year:
        return _daysInYear;
    }
  }

  @override
  Widget build(BuildContext context) {
    var expensePerDay = 0.0;
    var incomePerDay = 0.0;

    for (final p in payments) {
      if (!p.isActive) continue;
      final days = p.intervalCount * _unitDays(p.intervalUnit);
      if (days <= 0) continue;
      final perDay = p.amount / days;
      if (p.type == TransactionType.income) {
        incomePerDay += perDay;
      } else if (p.type == TransactionType.expense) {
        expensePerDay += perDay;
      }
    }

    final hasExpense = expensePerDay > 0;
    final hasIncome = incomePerDay > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Шапка с подписями типов.
          Row(
            children: [
              const SizedBox(width: _labelWidth),
              if (hasExpense)
                const Expanded(
                  child: _HeaderLabel('Расходы', AppColors.expense),
                ),
              if (hasIncome)
                const Expanded(child: _HeaderLabel('Доходы', AppColors.income)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          _PeriodRow(
            label: 'День',
            expense: hasExpense ? expensePerDay : null,
            income: hasIncome ? incomePerDay : null,
          ),
          _PeriodRow(
            label: 'Неделя',
            expense: hasExpense ? expensePerDay * 7 : null,
            income: hasIncome ? incomePerDay * 7 : null,
          ),
          _PeriodRow(
            label: 'Месяц',
            expense: hasExpense ? expensePerDay * _daysInMonth : null,
            income: hasIncome ? incomePerDay * _daysInMonth : null,
          ),
          _PeriodRow(
            label: 'Год',
            expense: hasExpense ? expensePerDay * _daysInYear : null,
            income: hasIncome ? incomePerDay * _daysInYear : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Суммы усреднены и приведены к каждому периоду.',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  static const double _labelWidth = 68;
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.label, this.expense, this.income});

  final String label;
  final double? expense;
  final double? income;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: RecurringSummaryCard._labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (expense != null)
            Expanded(
              child: _Amount(value: expense!, color: AppColors.expense),
            ),
          if (income != null)
            Expanded(
              child: _Amount(value: income!, color: AppColors.income),
            ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        formatMoneyAbs(value),
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}
