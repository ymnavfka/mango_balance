import '../../../../core/enums/transaction_type.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../entities/category_averages.dart';
import '../entities/category_breakdown.dart';
import '../entities/period_range.dart';
import '../entities/period_type.dart';
import 'build_category_breakdown.dart';
import 'compute_period_range.dart';

/// Uses one category layout for both charts, ranked by the entire history.
class BuildCategoryComparison {
  BuildCategoryComparison({
    required BuildCategoryBreakdown buildCategoryBreakdown,
    required ComputePeriodRange computePeriodRange,
  }) : _buildCategoryBreakdown = buildCategoryBreakdown,
       _computePeriodRange = computePeriodRange;

  final BuildCategoryBreakdown _buildCategoryBreakdown;
  final ComputePeriodRange _computePeriodRange;

  ({
    List<CategoryBreakdown> income,
    List<CategoryBreakdown> expense,
    CategoryAverages? averages,
  })
  call({
    required List<TransactionEntity> transactions,
    required PeriodType periodType,
    required PeriodRange currentRange,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final history = transactions
        .where(
          (tx) =>
              tx.type != TransactionType.transfer &&
              tx.date.value.isBefore(tomorrow),
        )
        .toList();
    if (history.isEmpty) {
      return (income: const [], expense: const [], averages: null);
    }

    final incomeTemplate = _buildCategoryBreakdown(
      transactions: history,
      type: TransactionType.income,
    );
    final expenseTemplate = _buildCategoryBreakdown(
      transactions: history,
      type: TransactionType.expense,
    );
    final selectedIncome = <int, double>{};
    final selectedExpense = <int, double>{};
    final referenceIncome = <int, double>{};
    final referenceExpense = <int, double>{};

    final earliest = history
        .map((tx) => tx.date.value)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final firstDay = DateTime(earliest.year, earliest.month, earliest.day);
    final firstRange = _computePeriodRange(type: periodType, anchor: firstDay);
    // A first transaction on the first day is enough: transaction dates are
    // calendar dates, so its time of day must not discard a complete period.
    final referenceStart = firstDay == firstRange.start
        ? firstRange.start
        : firstRange.end;
    final referenceEnd = _computePeriodRange(
      type: periodType,
      anchor: today,
    ).start;
    final periodCount = periodType == PeriodType.allTime
        ? 0
        : _periodCount(periodType, referenceStart, referenceEnd);
    final matchesElapsedDays =
        periodType != PeriodType.day &&
        periodType != PeriodType.allTime &&
        currentRange.contains(today);

    // Aggregate each transaction once. Empty calendar periods are retained in
    // the divisor without scanning the transaction list for every period.
    for (final tx in history) {
      if (currentRange.contains(tx.date.value)) {
        _add(
          tx.type == TransactionType.income ? selectedIncome : selectedExpense,
          tx,
        );
      }
      if (periodCount == 0 ||
          tx.date.value.isBefore(referenceStart) ||
          !tx.date.value.isBefore(referenceEnd) ||
          (matchesElapsedDays &&
              !_withinElapsedDays(tx.date.value, today, periodType))) {
        continue;
      }
      _add(
        tx.type == TransactionType.income ? referenceIncome : referenceExpense,
        tx,
      );
    }

    final income = _withAmounts(incomeTemplate, selectedIncome);
    final expense = _withAmounts(expenseTemplate, selectedExpense);
    if (periodType == PeriodType.allTime) {
      return (income: income, expense: expense, averages: null);
    }
    final averageIncome = _withAmounts(
      incomeTemplate,
      referenceIncome,
      divisor: periodCount,
    );
    final averageExpense = _withAmounts(
      expenseTemplate,
      referenceExpense,
      divisor: periodCount,
    );
    return (
      income: income,
      expense: expense,
      averages: CategoryAverages(
        periodCount: periodCount,
        historyStart: periodCount == 0 ? null : referenceStart,
        historyEnd: periodCount == 0 ? null : referenceEnd,
        matchesElapsedDays: matchesElapsedDays,
        elapsedDays: matchesElapsedDays
            ? _calendarDays(currentRange.start, today) + 1
            : null,
        incomeBreakdown: averageIncome,
        expenseBreakdown: averageExpense,
        totalIncome: _total(averageIncome),
        totalExpense: _total(averageExpense),
      ),
    );
  }

  static void _add(Map<int, double> amounts, TransactionEntity tx) {
    amounts.update(
      tx.categoryId,
      (amount) => amount + tx.amount.value,
      ifAbsent: () => tx.amount.value,
    );
  }

  static int _periodCount(PeriodType type, DateTime start, DateTime end) {
    if (!start.isBefore(end)) return 0;
    return switch (type) {
      PeriodType.day => _calendarDays(start, end),
      PeriodType.week => _calendarDays(start, end) ~/ 7,
      PeriodType.month =>
        (end.year - start.year) * 12 + end.month - start.month,
      PeriodType.year => end.year - start.year,
      PeriodType.allTime => 0,
    };
  }

  static int _calendarDays(DateTime start, DateTime end) => DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

  static bool _withinElapsedDays(
    DateTime date,
    DateTime today,
    PeriodType type,
  ) => switch (type) {
    PeriodType.week => date.weekday <= today.weekday,
    // Day/month comparisons naturally clamp to shorter months and years.
    PeriodType.month => date.day <= today.day,
    PeriodType.year =>
      date.month < today.month ||
          (date.month == today.month && date.day <= today.day),
    PeriodType.day || PeriodType.allTime => true,
  };

  static List<CategoryBreakdown> _withAmounts(
    List<CategoryBreakdown> template,
    Map<int, double> amounts, {
    int divisor = 1,
  }) {
    final total = amounts.values.fold<double>(0, (sum, amount) => sum + amount);
    CategoryBreakdown build(CategoryBreakdown entry) {
      final children = entry.children.map(build).toList();
      final amount = entry.hasChildren
          ? entry.children.fold<double>(
              0,
              (sum, child) => sum + (amounts[child.categoryId] ?? 0),
            )
          : amounts[entry.categoryId] ?? 0;
      return CategoryBreakdown(
        categoryId: entry.categoryId,
        categoryName: entry.categoryName,
        amount: divisor == 0 ? 0 : amount / divisor,
        share: total == 0 ? 0 : amount / total,
        children: children,
      );
    }

    return template.map(build).toList();
  }

  static double _total(List<CategoryBreakdown> breakdown) =>
      breakdown.fold<double>(0, (sum, category) => sum + category.amount);
}
