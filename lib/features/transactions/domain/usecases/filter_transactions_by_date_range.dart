import 'package:flutter/material.dart';

import '../entities/transaction.dart';

class FilterTransactionsByDateRange {
  List<TransactionEntity> call(
    List<TransactionEntity> transactions,
    DateTimeRange? range,
  ) {
    if (range == null) return transactions;

    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final endExclusive = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
    ).add(const Duration(days: 1));

    return transactions.where((tx) {
      final date = tx.date.value;
      return !date.isBefore(start) && date.isBefore(endExclusive);
    }).toList();
  }
}
