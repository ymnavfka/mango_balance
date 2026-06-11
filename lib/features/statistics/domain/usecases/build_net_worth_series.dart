import '../../../../core/enums/transaction_type.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../entities/net_worth_point.dart';

/// Строит ряд накопленного баланса (капитала) за всё время.
///
/// Переводы не учитываются: они перемещают деньги между счетами и не меняют
/// общий капитал. Точки агрегируются по дням; ряд продлевается до текущего
/// дня, чтобы график доходил до «сегодня».
class BuildNetWorthSeries {
  List<NetWorthPoint> call({
    required List<TransactionEntity> transactions,
    required DateTime now,
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

    if (deltasByDay.isEmpty) {
      return const [];
    }

    final days = deltasByDay.keys.toList()..sort();
    final points = <NetWorthPoint>[];
    var balance = 0.0;
    for (final day in days) {
      balance += deltasByDay[day]!;
      points.add(NetWorthPoint(date: day, balance: balance));
    }

    final today = DateTime(now.year, now.month, now.day);
    if (points.last.date.isBefore(today)) {
      points.add(NetWorthPoint(date: today, balance: balance));
    }

    // До первой операции капитал был нулевым; стартовая точка также
    // гарантирует минимум две точки для отрисовки линии.
    final first = points.first.date;
    points.insert(
      0,
      NetWorthPoint(date: first.subtract(const Duration(days: 1)), balance: 0),
    );

    return points;
  }
}
