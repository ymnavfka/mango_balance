import 'category_breakdown.dart';
import 'period_bucket.dart';
import 'period_range.dart';
import 'period_type.dart';

class StatisticsSnapshot {
  StatisticsSnapshot({
    required this.periodType,
    required this.anchorDate,
    required this.currentRange,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
    required this.totalIncome,
    required this.totalExpense,
    required this.timeSeries,
    required this.canNavigateForward,
    required this.canNavigateBack,
    required this.hasAnyTransactions,
  });

  factory StatisticsSnapshot.empty() {
    final now = DateTime.now();
    return StatisticsSnapshot(
      periodType: PeriodType.week,
      anchorDate: now,
      currentRange: PeriodRange(start: now, end: now, label: ''),
      incomeBreakdown: const [],
      expenseBreakdown: const [],
      totalIncome: 0,
      totalExpense: 0,
      timeSeries: const [],
      canNavigateForward: false,
      canNavigateBack: false,
      hasAnyTransactions: false,
    );
  }

  final PeriodType periodType;
  final DateTime anchorDate;
  final PeriodRange currentRange;
  final List<CategoryBreakdown> incomeBreakdown;
  final List<CategoryBreakdown> expenseBreakdown;
  final double totalIncome;
  final double totalExpense;
  final List<PeriodBucket> timeSeries;
  final bool canNavigateForward;
  final bool canNavigateBack;
  final bool hasAnyTransactions;

  double get netBalance => totalIncome - totalExpense;
}
