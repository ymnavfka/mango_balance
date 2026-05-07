import '../../../../core/enums/transaction_type.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../entities/period_type.dart';
import '../entities/statistics_snapshot.dart';
import 'build_category_breakdown.dart';
import 'build_time_series.dart';
import 'compute_period_range.dart';

class BuildStatisticsSnapshot {
  BuildStatisticsSnapshot({
    required ComputePeriodRange computePeriodRange,
    required BuildCategoryBreakdown buildCategoryBreakdown,
    required BuildTimeSeries buildTimeSeries,
  }) : _computePeriodRange = computePeriodRange,
       _buildCategoryBreakdown = buildCategoryBreakdown,
       _buildTimeSeries = buildTimeSeries;

  final ComputePeriodRange _computePeriodRange;
  final BuildCategoryBreakdown _buildCategoryBreakdown;
  final BuildTimeSeries _buildTimeSeries;

  StatisticsSnapshot call({
    required List<TransactionEntity> transactions,
    required PeriodType periodType,
    required DateTime anchorDate,
    required DateTime now,
  }) {
    if (transactions.isEmpty) {
      return StatisticsSnapshot.empty().copyWithBasics(
        periodType: periodType,
        anchorDate: anchorDate,
      );
    }

    final accountable = transactions
        .where((tx) => tx.type != TransactionType.transfer)
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

    final inRange = transactions
        .where((tx) => currentRange.contains(tx.date.value))
        .toList();

    final incomeBreakdown = _buildCategoryBreakdown(
      transactions: inRange,
      type: TransactionType.income,
    );
    final expenseBreakdown = _buildCategoryBreakdown(
      transactions: inRange,
      type: TransactionType.expense,
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
      incomeBreakdown: incomeBreakdown,
      expenseBreakdown: expenseBreakdown,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      timeSeries: timeSeries,
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
      canNavigateForward: false,
      canNavigateBack: false,
      hasAnyTransactions: false,
    );
  }
}
