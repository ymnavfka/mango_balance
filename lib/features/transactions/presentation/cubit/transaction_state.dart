import 'package:flutter/material.dart';

import '../../../../core/enums/transaction_type.dart';
import '../../domain/entities/transaction.dart';

class TransactionState {
  TransactionState({
    required this.transactions,
    required this.allTransactions,
    required this.sections,
    required this.selectedAccountId,
    required this.totalBalance,
    required this.selectedBalance,
    required this.accountBalances,
    required this.visibleTypes,
    required this.dateRange,
  });

  factory TransactionState.initial() {
    return TransactionState(
      transactions: [],
      allTransactions: [],
      sections: [],
      selectedAccountId: null,
      totalBalance: 0,
      selectedBalance: 0,
      accountBalances: {},
      visibleTypes: TransactionType.values.toSet(),
      dateRange: null,
    );
  }

  final List<TransactionEntity> transactions;
  final List<TransactionEntity> allTransactions;
  final List<TransactionSection> sections;
  final int? selectedAccountId;
  final double totalBalance;
  final double selectedBalance;
  final Map<int, double> accountBalances;
  final Set<TransactionType> visibleTypes;
  final DateTimeRange? dateRange;

  TransactionState copyWith({
    List<TransactionEntity>? transactions,
    List<TransactionEntity>? allTransactions,
    List<TransactionSection>? sections,
    Object? selectedAccountId = _unset,
    double? totalBalance,
    double? selectedBalance,
    Map<int, double>? accountBalances,
    Set<TransactionType>? visibleTypes,
    Object? dateRange = _unset,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      allTransactions: allTransactions ?? this.allTransactions,
      sections: sections ?? this.sections,
      selectedAccountId: identical(selectedAccountId, _unset)
          ? this.selectedAccountId
          : selectedAccountId as int?,
      totalBalance: totalBalance ?? this.totalBalance,
      selectedBalance: selectedBalance ?? this.selectedBalance,
      accountBalances: accountBalances ?? this.accountBalances,
      visibleTypes: visibleTypes ?? this.visibleTypes,
      dateRange: identical(dateRange, _unset)
          ? this.dateRange
          : dateRange as DateTimeRange?,
    );
  }

  static const Object _unset = Object();
}

class TransactionSection {
  TransactionSection({required this.title, required this.transactions});
  final String title;
  final List<TransactionEntity> transactions;
}
