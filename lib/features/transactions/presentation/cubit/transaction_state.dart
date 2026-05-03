import '../../domain/entities/transaction.dart';

class TransactionState {
  TransactionState({
    required this.transactions,
    required this.sections,
    required this.selectedAccountId,
    required this.totalBalance,
    required this.selectedBalance,
    required this.accountBalances,
  });

  factory TransactionState.initial() {
    return TransactionState(
      transactions: [],
      sections: [],
      selectedAccountId: null,
      totalBalance: 0,
      selectedBalance: 0,
      accountBalances: {},
    );
  }

  final List<TransactionEntity> transactions;
  final List<TransactionSection> sections;
  final int? selectedAccountId;
  final double totalBalance;
  final double selectedBalance;
  final Map<int, double> accountBalances;

  TransactionState copyWith({
    List<TransactionEntity>? transactions,
    List<TransactionSection>? sections,
    int? selectedAccountId,
    double? totalBalance,
    double? selectedBalance,
    Map<int, double>? accountBalances,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      sections: sections ?? this.sections,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      totalBalance: totalBalance ?? this.totalBalance,
      selectedBalance: selectedBalance ?? this.selectedBalance,
      accountBalances: accountBalances ?? this.accountBalances,
    );
  }
}

class TransactionSection {
  TransactionSection({required this.title, required this.transactions});
  final String title;
  final List<TransactionEntity> transactions;
}
