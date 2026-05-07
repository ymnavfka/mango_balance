import '../../../../core/enums/transaction_type.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../entities/period_bucket.dart';
import '../entities/period_type.dart';
import 'compute_period_range.dart';

class BuildTimeSeries {
  BuildTimeSeries(this._computePeriodRange);

  final ComputePeriodRange _computePeriodRange;

  List<PeriodBucket> call({
    required List<TransactionEntity> transactions,
    required PeriodType type,
    required DateTime now,
  }) {
    final accountable = transactions
        .where((tx) => tx.type != TransactionType.transfer)
        .toList();

    if (accountable.isEmpty) {
      return const [];
    }

    final earliest = accountable
        .map((tx) => tx.date.value)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final granularity = type == PeriodType.allTime ? PeriodType.year : type;

    final firstAnchor = DateTime(earliest.year, earliest.month, earliest.day);
    final lastAnchor = DateTime(now.year, now.month, now.day);

    final buckets = <PeriodBucket>[];
    var cursor = firstAnchor;
    var safety = 0;
    const safetyLimit = 5000;

    while (!cursor.isAfter(lastAnchor) && safety < safetyLimit) {
      final range = _computePeriodRange(type: granularity, anchor: cursor);

      double income = 0;
      double expense = 0;
      for (final tx in accountable) {
        if (!range.contains(tx.date.value)) continue;
        if (tx.type == TransactionType.income) {
          income += tx.amount.value;
        } else if (tx.type == TransactionType.expense) {
          expense += tx.amount.value;
        }
      }

      buckets.add(PeriodBucket(range: range, income: income, expense: expense));

      cursor = _computePeriodRange.shiftAnchor(
        type: granularity,
        anchor: cursor,
        direction: 1,
      );
      safety++;
    }

    return buckets;
  }
}
