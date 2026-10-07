import 'category_breakdown.dart';

/// Category amounts averaged over completed calendar periods in the history.
class CategoryAverages {
  const CategoryAverages({
    required this.periodCount,
    required this.historyStart,
    required this.historyEnd,
    required this.matchesElapsedDays,
    required this.elapsedDays,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
    required this.totalIncome,
    required this.totalExpense,
  });

  final int periodCount;

  /// First included complete calendar period, or null when none are available.
  final DateTime? historyStart;

  /// Exclusive end of the last included complete calendar period.
  final DateTime? historyEnd;
  final bool matchesElapsedDays;
  final int? elapsedDays;
  final List<CategoryBreakdown> incomeBreakdown;
  final List<CategoryBreakdown> expenseBreakdown;
  final double totalIncome;
  final double totalExpense;
}
