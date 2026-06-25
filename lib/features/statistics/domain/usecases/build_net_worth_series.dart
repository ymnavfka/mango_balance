import '../../../../core/enums/transaction_type.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../entities/net_worth_point.dart';

/// Строит ряд накопленного баланса (капитала) за всё время.
///
/// Переводы не учитываются: они перемещают деньги между счетами и не меняют
/// общий капитал. Точки агрегируются по дням; ряд продлевается до текущего
/// дня, чтобы график доходил до «сегодня».
class BuildNetWorthSeries {
  /// [startingBalance] — сумма изначальных балансов всех счетов: капитал на
  /// момент до первой транзакции. Линия строится поверх него.
  List<NetWorthPoint> call({
    required List<TransactionEntity> transactions,
    required DateTime now,
    double startingBalance = 0,
  }) {
    final deltasByDay = <DateTime, double>{};
    for (final tx in transactions) {
      if (tx.type == TransactionType.transfer) continue;
      final date = tx.date.value;
      final day = DateTime(date.year, date.month, date.day);
      final delta = tx.type == TransactionType.income
          ? tx.amount.value
          : -tx.amount.value;
      deltasByDay[day] = (deltasByDay[day] ?? 0) + delta;
    }

    final today = DateTime(now.year, now.month, now.day);

    if (deltasByDay.isEmpty) {
      if (startingBalance == 0) {
        return const [];
      }
      // Транзакций нет, но есть изначальный баланс — ровная линия на его уровне.
      return [
        NetWorthPoint(
          date: today.subtract(const Duration(days: 1)),
          balance: startingBalance,
        ),
        NetWorthPoint(date: today, balance: startingBalance),
      ];
    }

    final days = deltasByDay.keys.toList()..sort();
    final points = <NetWorthPoint>[];
    var balance = startingBalance;
    for (final day in days) {
      balance += deltasByDay[day]!;
      points.add(NetWorthPoint(date: day, balance: balance));
    }

    if (points.last.date.isBefore(today)) {
      points.add(NetWorthPoint(date: today, balance: balance));
    }

    // До первой операции капитал равнялся сумме изначальных балансов; стартовая
    // точка также гарантирует минимум две точки для отрисовки линии.
    final first = points.first.date;
    points.insert(
      0,
      NetWorthPoint(
        date: first.subtract(const Duration(days: 1)),
        balance: startingBalance,
      ),
    );

    return points;
  }
}
