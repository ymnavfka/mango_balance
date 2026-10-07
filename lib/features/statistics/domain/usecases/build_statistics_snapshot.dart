import '../../../../core/enums/transaction_type.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../entities/period_type.dart';
import '../entities/statistics_snapshot.dart';
import 'build_category_breakdown.dart';
import 'build_category_comparison.dart';
import 'build_net_worth_series.dart';
import 'build_time_series.dart';
import 'compute_period_range.dart';

class BuildStatisticsSnapshot {
  BuildStatisticsSnapshot({
    required ComputePeriodRange computePeriodRange,
    required BuildCategoryBreakdown buildCategoryBreakdown,
    required BuildTimeSeries buildTimeSeries,
    required BuildNetWorthSeries buildNetWorthSeries,
  }) : _computePeriodRange = computePeriodRange,
       _buildCategoryComparison = BuildCategoryComparison(
         buildCategoryBreakdown: buildCategoryBreakdown,
         computePeriodRange: computePeriodRange,
       ),
       _buildTimeSeries = buildTimeSeries,
       _buildNetWorthSeries = buildNetWorthSeries;

  final ComputePeriodRange _computePeriodRange;
  final BuildCategoryComparison _buildCategoryComparison;
  final BuildTimeSeries _buildTimeSeries;
  final BuildNetWorthSeries _buildNetWorthSeries;

  StatisticsSnapshot call({
    required List<TransactionEntity> transactions,
    required PeriodType periodType,
    required DateTime anchorDate,
    required DateTime now,
    double initialBalanceTotal = 0,
  }) {
    if (transactions.isEmpty) {
      return StatisticsSnapshot.empty().copyWithBasics(
        periodType: periodType,
        anchorDate: anchorDate,
      );
    }

    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final accountable = transactions
        .where(
          (tx) =>
              tx.type != TransactionType.transfer &&
              tx.date.value.isBefore(tomorrow),
        )
        .toList();

    final earliest = accountable.isEmpty
        ? null
        : accountable
              .map((tx) => tx.date.value)
              .reduce((a, b) => a.isBefore(b) ? a : b);

    final currentRange = _computePeriodRange(
      type: periodType,
      anchor: anchorDate,
      earliestTransactionDate: earliest,
    );

    final inRange = accountable
        .where((tx) => currentRange.contains(tx.date.value))
        .toList();

    final comparison = _buildCategoryComparison(
      transactions: accountable,
      periodType: periodType,
      currentRange: currentRange,
      now: now,
    );

    final totalIncome = inRange
        .where((tx) => tx.type == TransactionType.income)
        .fold<double>(0, (sum, tx) => sum + tx.amount.value);
    final totalExpense = inRange
        .where((tx) => tx.type == TransactionType.expense)
        .fold<double>(0, (sum, tx) => sum + tx.amount.value);

    final timeSeries = _buildTimeSeries(
      transactions: transactions,
      type: periodType,
      now: now,
    );

    final netWorthSeries = _buildNetWorthSeries(
      transactions: transactions,
      now: now,
      startingBalance: initialBalanceTotal,
    );

    final canNavigateBack =
        periodType != PeriodType.allTime &&
        earliest != null &&
        currentRange.start.isAfter(
          DateTime(earliest.year, earliest.month, earliest.day),
        );
    final canNavigateForward =
        periodType != PeriodType.allTime && currentRange.end.isBefore(now);

    return StatisticsSnapshot(
      periodType: periodType,
      anchorDate: anchorDate,
      currentRange: currentRange,
      incomeBreakdown: comparison.income,
      expenseBreakdown: comparison.expense,
      categoryAverages: comparison.averages,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      timeSeries: timeSeries,
      netWorthSeries: netWorthSeries,
      canNavigateForward: canNavigateForward,
      canNavigateBack: canNavigateBack,
      hasAnyTransactions: accountable.isNotEmpty,
    );
  }
}

extension on StatisticsSnapshot {
  StatisticsSnapshot copyWithBasics({
    required PeriodType periodType,
    required DateTime anchorDate,
  }) {
    return StatisticsSnapshot(
      periodType: periodType,
      anchorDate: anchorDate,
      currentRange: currentRange,
      incomeBreakdown: incomeBreakdown,
      expenseBreakdown: expenseBreakdown,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      timeSeries: timeSeries,
      netWorthSeries: netWorthSeries,
      canNavigateForward: false,
      canNavigateBack: false,
      hasAnyTransactions: false,
    );
  }
}
