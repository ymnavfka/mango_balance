import '../../../../core/enums/transaction_type.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../entities/budget.dart';
import '../entities/budget_period.dart';
import '../entities/budget_progress.dart';

class BuildBudgetsProgress {
  List<BudgetProgress> call({
    required List<BudgetEntity> budgets,
    required List<TransactionEntity> transactions,
    required List<CategoryEntity> categories,
    required DateTime now,
  }) {
    final categoryNameById = {
      for (final category in categories) category.id: category.name,
    };

    final result = <BudgetProgress>[];
    for (final budget in budgets) {
      final range = _periodRange(budget.period, now);
      final allowedCategoryIds = budget.allCategories
          ? null
          : budget.categoryIds.toSet();

      double spent = 0;
      for (final tx in transactions) {
        if (tx.type != TransactionType.expense) continue;
        final date = tx.date.value;
        if (date.isBefore(range.start) || !date.isBefore(range.end)) continue;
        if (allowedCategoryIds != null &&
            !allowedCategoryIds.contains(tx.categoryId)) {
          continue;
        }
        spent += tx.amount.value;
      }

      final daysRemaining = _daysBetween(now, range.end);

      final names = budget.allCategories
          ? const <String>[]
          : budget.categoryIds
                .map((id) => categoryNameById[id] ?? 'Удалённая категория')
                .toList();

      result.add(
        BudgetProgress(
          budget: budget,
          spent: spent,
          periodStart: range.start,
          periodEnd: range.end,
          daysRemaining: daysRemaining,
          categoryNames: names,
        ),
      );
    }

    result.sort((a, b) => b.fillRatio.compareTo(a.fillRatio));
    return result;
  }

  ({DateTime start, DateTime end}) _periodRange(
    BudgetPeriod period,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case BudgetPeriod.week:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start: start, end: start.add(const Duration(days: 7)));
      case BudgetPeriod.month:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 1);
        return (start: start, end: end);
      case BudgetPeriod.year:
        final start = DateTime(today.year, 1, 1);
        final end = DateTime(today.year + 1, 1, 1);
        return (start: start, end: end);
    }
  }

  int _daysBetween(DateTime now, DateTime end) {
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final diff = endDay.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }
}
