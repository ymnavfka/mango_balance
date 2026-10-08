import 'package:flutter_test/flutter_test.dart';
import 'package:mango_balance/core/enums/transaction_type.dart';
import 'package:mango_balance/features/statistics/domain/entities/net_worth_history.dart';
import 'package:mango_balance/features/statistics/domain/entities/net_worth_point.dart';
import 'package:mango_balance/features/statistics/domain/usecases/build_net_worth_series.dart';

import 'build_statistics_snapshot_test.dart' show transaction;

void main() {
  int day(int date) => NetWorthHistory.dayNumber(DateTime(2026, 9, date));
  final history = NetWorthHistory([
    NetWorthPoint(date: DateTime(2026, 9, 1), balance: 100),
    NetWorthPoint(date: DateTime(2026, 9, 4), balance: 150.25),
    NetWorthPoint(date: DateTime(2026, 9, 9), balance: -20),
    NetWorthPoint(date: DateTime(2026, 9, 30), balance: -20),
  ]);

  test('days without transactions retain the last closing balance', () {
    expect(history.balanceAt(day(3)), 100);
    expect(history.balanceAt(day(4)), 150.25);
    expect(history.balanceAt(day(8)), 150.25);
    expect(history.balanceAt(day(15)), -20);
    expect(history.openingBalance(day(4)), 100);
    expect(history.openingBalance(day(9)), 150.25);
  });

  test(
    'range starts with carried balance and measures from opening balance',
    () {
      final window = history.window(day(4), day(15));
      expect(window.map((p) => p.date), [
        DateTime(2026, 9, 4),
        DateTime(2026, 9, 9),
        DateTime(2026, 9, 15),
      ]);
      expect(window.map((p) => p.balance), [150.25, -20, -20]);
      expect(window.last.balance - history.openingBalance(day(4)), -120);
      expect(history.window(day(5), day(7)).map((p) => p.balance), [
        150.25,
        150.25,
      ]);
      expect(history.window(day(4), day(4)).single.balance, 150.25);
    },
  );

  test(
    'calendar indices round trip across leap day, year and DST boundaries',
    () {
      for (final date in [
        DateTime(2024, 2, 29),
        DateTime(2026, 3, 29),
        DateTime(2026, 10, 25),
        DateTime(2027),
      ]) {
        final number = NetWorthHistory.dayNumber(date);
        expect(NetWorthHistory.dateForDay(number), date);
        expect(
          NetWorthHistory.dateForDay(number + 1),
          DateTime(date.year, date.month, date.day + 1),
        );
      }
    },
  );

  test('series aggregates a day, excludes transfers and future dates', () {
    final points = BuildNetWorthSeries()(
      startingBalance: 200,
      now: DateTime(2026, 9, 8),
      transactions: [
        transaction(DateTime(2026, 9, 1, 10), 50, type: TransactionType.income),
        transaction(DateTime(2026, 9, 1, 11), 10.25),
        transaction(DateTime(2026, 9, 3), 500, type: TransactionType.transfer),
        transaction(DateTime(2026, 9, 9), 10000, type: TransactionType.income),
      ],
    );
    expect(points.map((p) => p.balance), [200, 239.75, 239.75]);
    expect(points.first.date, DateTime(2026, 8, 31));
    expect(points.last.date, DateTime(2026, 9, 8));
  });

  test('an initial balance without operations remains flat', () {
    final points = BuildNetWorthSeries()(
      transactions: [],
      now: DateTime(2026, 9, 8),
      startingBalance: -12.34,
    );
    expect(points.map((p) => p.balance), [-12.34, -12.34]);
  });
}
