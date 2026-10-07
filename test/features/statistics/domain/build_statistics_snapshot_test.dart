import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/enums/transaction_type.dart';
import 'package:mango_balance/features/statistics/domain/entities/category_breakdown.dart';
import 'package:mango_balance/features/statistics/domain/entities/period_type.dart';
import 'package:mango_balance/features/statistics/domain/entities/statistics_snapshot.dart';
import 'package:mango_balance/features/statistics/domain/usecases/build_category_breakdown.dart';
import 'package:mango_balance/features/statistics/domain/usecases/build_net_worth_series.dart';
import 'package:mango_balance/features/statistics/domain/usecases/build_statistics_snapshot.dart';
import 'package:mango_balance/features/statistics/domain/usecases/build_time_series.dart';
import 'package:mango_balance/features/statistics/domain/usecases/compute_period_range.dart';
import 'package:mango_balance/features/transactions/domain/entities/transaction.dart';
import 'package:mango_balance/features/transactions/domain/value_objects/amount.dart';
import 'package:mango_balance/features/transactions/domain/value_objects/transaction_date.dart';

TransactionEntity transaction(
  DateTime date,
  double amount, {
  int category = 1,
  TransactionType type = TransactionType.expense,
}) => TransactionEntity(
  id: date.millisecondsSinceEpoch + category,
  type: type,
  amount: Amount(amount),
  date: TransactionDate(date),
  categoryId: category,
  categoryName: 'Категория $category',
  accountId: 1,
  accountName: 'Счёт',
  toAccountId: type == TransactionType.transfer ? 2 : null,
  toAccountName: type == TransactionType.transfer ? 'Другой счёт' : null,
  comment: null,
);

StatisticsSnapshot snapshot(
  List<TransactionEntity> transactions, {
  required DateTime now,
  DateTime? anchor,
  PeriodType type = PeriodType.month,
}) {
  final ranges = ComputePeriodRange();
  return BuildStatisticsSnapshot(
    computePeriodRange: ranges,
    buildCategoryBreakdown: BuildCategoryBreakdown(),
    buildTimeSeries: BuildTimeSeries(ranges),
    buildNetWorthSeries: BuildNetWorthSeries(),
  )(
    transactions: transactions,
    periodType: type,
    anchorDate: anchor ?? now,
    now: now,
  );
}

CategoryBreakdown category(List<CategoryBreakdown> breakdown, int id) =>
    breakdown.firstWhere((entry) => entry.categoryId == id);

void main() {
  test(
    'averages category amounts across completed months, including empty ones',
    () {
      final result = snapshot(
        [
          transaction(
            DateTime(2024, 1, 1, 16),
            100,
            type: TransactionType.income,
          ),
          transaction(DateTime(2024, 1, 5), 30),
          transaction(DateTime(2024, 2, 20), 90, category: 2),
          transaction(DateTime(2024, 4, 4), 80),
        ],
        anchor: DateTime(2024, 2, 1),
        now: DateTime(2024, 4, 15),
      );
      final average = result.categoryAverages!;
      expect(average.periodCount, 3);
      expect(average.historyStart, DateTime(2024, 1, 1));
      expect(average.historyEnd, DateTime(2024, 4, 1));
      expect(average.totalExpense, 40);
      expect(average.totalIncome, closeTo(100 / 3, 0.000001));
      expect(average.matchesElapsedDays, isFalse);
      expect(average.elapsedDays, isNull);
      expect(result.totalExpense, 90);
      expect(result.totalIncome, 0);
      expect(category(result.expenseBreakdown, 1).amount, 0);
      expect(category(result.expenseBreakdown, 2).amount, 90);
      expect(category(average.expenseBreakdown, 1).amount, 10);
      expect(category(average.expenseBreakdown, 2).amount, 30);
      expect(category(average.expenseBreakdown, 1).share, .25);
      expect(category(average.expenseBreakdown, 2).share, .75);
      expect(result.incomeBreakdown.single.share, 0);
    },
  );

  test('excludes an initial partial month but retains later empty months', () {
    final result = snapshot(
      [
        transaction(DateTime(2024, 1, 12), 600),
        transaction(DateTime(2024, 2, 10), 80),
      ],
      anchor: DateTime(2024, 3, 1),
      now: DateTime(2024, 4, 10),
    );
    expect(result.categoryAverages!.periodCount, 2);
    expect(result.categoryAverages!.historyStart, DateTime(2024, 2, 1));
    expect(result.categoryAverages!.totalExpense, 40);
    expect(result.totalExpense, 0);
    expect(result.expenseBreakdown.single.amount, 0);
  });

  test('reports insufficient history with matching zero-valued categories', () {
    final result = snapshot([
      transaction(DateTime(2024, 5, 3), 120),
    ], now: DateTime(2024, 5, 20));
    final average = result.categoryAverages!;
    expect(average.periodCount, 0);
    expect(average.historyStart, isNull);
    expect(average.historyEnd, isNull);
    expect(average.totalExpense, 0);
    expect(average.totalIncome, 0);
    expect(average.expenseBreakdown.single.categoryId, 1);
    expect(average.expenseBreakdown.single.amount, 0);
    expect(average.expenseBreakdown.single.share, 0);
    expect(average.incomeBreakdown, isEmpty);
  });

  test(
    'has no comparison for no history, transfers only, future only, or all time',
    () {
      final now = DateTime(2024, 5, 20);
      for (final transactions in <List<TransactionEntity>>[
        [],
        [
          transaction(
            DateTime(2023, 1, 1),
            500,
            type: TransactionType.transfer,
          ),
        ],
        [transaction(DateTime(2024, 5, 21), 500)],
      ]) {
        final result = snapshot(transactions, now: now);
        expect(result.categoryAverages, isNull);
        expect(result.hasAnyTransactions, isFalse);
        expect(result.expenseBreakdown, isEmpty);
      }
      final allTime = snapshot(
        [transaction(DateTime(2023, 1, 1), 500)],
        now: now,
        type: PeriodType.allTime,
      );
      expect(allTime.categoryAverages, isNull);
      expect(allTime.totalExpense, 500);
    },
  );

  test(
    'day averages include empty days and compare the whole current calendar day',
    () {
      final result = snapshot(
        [
          transaction(DateTime(2024, 1, 1, 18), 12),
          transaction(DateTime(2024, 1, 3), 18),
          transaction(DateTime(2024, 1, 5, 20), 40),
          transaction(DateTime(2024, 1, 6), 900),
        ],
        now: DateTime(2024, 1, 5, 9),
        type: PeriodType.day,
      );
      final average = result.categoryAverages!;
      expect(average.periodCount, 4);
      expect(average.totalExpense, 7.5);
      expect(average.matchesElapsedDays, isFalse);
      expect(average.elapsedDays, isNull);
      expect(result.totalExpense, 40);
    },
  );

  test('current weeks compare equivalent weekdays of all completed weeks', () {
    final transactions = [
      transaction(DateTime(2024, 1, 1, 18), 10),
      transaction(DateTime(2024, 1, 3), 30),
      transaction(DateTime(2024, 1, 5), 300),
      transaction(DateTime(2024, 1, 10), 50),
      transaction(DateTime(2024, 1, 24), 12),
    ];
    final current = snapshot(
      transactions,
      now: DateTime(2024, 1, 24),
      type: PeriodType.week,
    );
    expect(current.categoryAverages!.periodCount, 3);
    expect(current.categoryAverages!.matchesElapsedDays, isTrue);
    expect(current.categoryAverages!.elapsedDays, 3);
    expect(current.categoryAverages!.totalExpense, 30);
    final completed = snapshot(
      transactions,
      anchor: DateTime(2024, 1, 8),
      now: DateTime(2024, 1, 24),
      type: PeriodType.week,
    );
    expect(completed.categoryAverages!.totalExpense, 130);
    expect(completed.categoryAverages!.matchesElapsedDays, isFalse);
  });

  test('excludes an initial partial week', () {
    final result = snapshot(
      [
        transaction(DateTime(2024, 1, 2), 500),
        transaction(DateTime(2024, 1, 8), 20),
      ],
      now: DateTime(2024, 1, 17),
      type: PeriodType.week,
    );
    expect(result.categoryAverages!.periodCount, 1);
    expect(result.categoryAverages!.historyStart, DateTime(2024, 1, 8));
    expect(result.categoryAverages!.totalExpense, 20);
  });

  test(
    'current monthly prefix clamps at the end of shorter reference months',
    () {
      final result = snapshot([
        transaction(DateTime(2024, 1, 1), 10),
        transaction(DateTime(2024, 1, 31), 20),
        transaction(DateTime(2024, 2, 29), 30),
        transaction(DateTime(2024, 3, 31), 40),
      ], now: DateTime(2024, 3, 31));
      expect(result.categoryAverages!.periodCount, 2);
      expect(result.categoryAverages!.elapsedDays, 31);
      expect(result.categoryAverages!.totalExpense, 30);
      expect(result.totalExpense, 40);
    },
  );

  test(
    'current monthly prefix excludes later dates in longer reference months',
    () {
      final result = snapshot([
        transaction(DateTime(2024, 12, 1), 10),
        transaction(DateTime(2025, 1, 28), 30),
        transaction(DateTime(2025, 1, 29), 900),
      ], now: DateTime(2025, 2, 28));
      expect(result.categoryAverages!.periodCount, 2);
      expect(result.categoryAverages!.elapsedDays, 28);
      expect(result.categoryAverages!.totalExpense, 20);
    },
  );

  test('year prefixes match calendar month and day across leap years', () {
    final transactions = [
      transaction(DateTime(2022, 1, 1), 10),
      transaction(DateTime(2022, 3, 1), 20),
      transaction(DateTime(2022, 3, 2), 900),
      transaction(DateTime(2023, 3, 1), 30),
    ];
    final leapYear = snapshot(
      transactions,
      now: DateTime(2024, 3, 1),
      type: PeriodType.year,
    );
    expect(leapYear.categoryAverages!.periodCount, 2);
    expect(leapYear.categoryAverages!.elapsedDays, 61);
    expect(leapYear.categoryAverages!.totalExpense, 30);
    final leapDay = snapshot(
      [
        transaction(DateTime(2023, 1, 1), 10),
        transaction(DateTime(2023, 2, 28), 20),
        transaction(DateTime(2023, 3, 1), 900),
      ],
      now: DateTime(2024, 2, 29),
      type: PeriodType.year,
    );
    expect(leapDay.categoryAverages!.totalExpense, 30);
    final nonLeapYear = snapshot(
      [
        transaction(DateTime(2024, 1, 1), 10),
        transaction(DateTime(2024, 2, 28), 20),
        transaction(DateTime(2024, 2, 29), 900),
      ],
      now: DateTime(2025, 2, 28),
      type: PeriodType.year,
    );
    expect(nonLeapYear.categoryAverages!.elapsedDays, 59);
    expect(nonLeapYear.categoryAverages!.totalExpense, 30);
  });

  test(
    'excludes an initial partial year and includes selected completed year',
    () {
      final result = snapshot(
        [
          transaction(DateTime(2022, 6, 1), 1000),
          transaction(DateTime(2023, 6, 1), 100),
          transaction(DateTime(2024, 6, 1), 200),
        ],
        anchor: DateTime(2024, 1, 1),
        now: DateTime(2025, 3, 1),
        type: PeriodType.year,
      );
      expect(result.categoryAverages!.periodCount, 2);
      expect(result.categoryAverages!.historyStart, DateTime(2023, 1, 1));
      expect(result.categoryAverages!.totalExpense, 150);
      expect(result.totalExpense, 200);
    },
  );

  test(
    'charts preserve category order and Other membership across periods',
    () {
      final transactions = [
        for (var id = 1; id <= 8; id++)
          transaction(DateTime(2024, 1, 1), (10 - id) * 100, category: id),
        transaction(DateTime(2024, 2, 1), 350, category: 8),
        transaction(DateTime(2024, 3, 1), 200, category: 7),
      ];
      final february = snapshot(
        transactions,
        anchor: DateTime(2024, 2, 1),
        now: DateTime(2024, 4, 15),
      );
      final march = snapshot(
        transactions.reversed.toList(),
        anchor: DateTime(2024, 3, 1),
        now: DateTime(2024, 4, 15),
      );
      final average = february.categoryAverages!.expenseBreakdown;
      final expectedIds = [1, 2, 3, 4, 8, 5, null];
      for (final breakdown in [
        february.expenseBreakdown,
        average,
        march.expenseBreakdown,
        march.categoryAverages!.expenseBreakdown,
      ]) {
        expect(breakdown.map((entry) => entry.categoryId), expectedIds);
        expect(breakdown.last.children.map((entry) => entry.categoryId), [
          7,
          6,
        ]);
      }
      expect(february.expenseBreakdown.last.amount, 0);
      expect(march.expenseBreakdown.last.amount, 200);
      expect(
        category(average.last.children, 7).amount,
        closeTo(500 / 3, .000001),
      );
      expect(average.last.share, closeTo(900 / 4950, .000001));
      expect(
        average.fold<double>(0, (sum, entry) => sum + entry.share),
        closeTo(1, .000001),
      );
      expect(
        average.last.children.fold<double>(
          0,
          (sum, entry) => sum + entry.share,
        ),
        closeTo(average.last.share, .000001),
      );
    },
  );

  test(
    'transfers and future calendar dates do not affect categories or averages',
    () {
      final result = snapshot([
        transaction(DateTime(2023, 1, 1), 900, type: TransactionType.transfer),
        transaction(DateTime(2024, 1, 1), 60),
        transaction(DateTime(2024, 2, 5), 30),
        transaction(DateTime(2024, 3, 2, 20), 40),
        transaction(DateTime(2024, 3, 3), 9000, category: 2),
      ], now: DateTime(2024, 3, 2, 9));
      expect(result.categoryAverages!.historyStart, DateTime(2024, 1, 1));
      expect(result.categoryAverages!.periodCount, 2);
      expect(result.categoryAverages!.totalExpense, 30);
      expect(result.totalExpense, 40);
      expect(result.expenseBreakdown.map((entry) => entry.categoryId), [1]);
      expect(result.incomeBreakdown, isEmpty);
    },
  );
}
