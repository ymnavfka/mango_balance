import '../../../../core/enums/transaction_type.dart';
import '../../domain/entities/transaction.dart';

class TransactionState {
  TransactionState({
    required this.transactions,
    required this.sections,
    required this.selectedAccountId,
    required this.totalBalance,
    required this.selectedBalance,
    required this.accountBalances,
    required this.visibleTypes,
  });

  factory TransactionState.initial() {
    return TransactionState(
      transactions: [],
      sections: [],
      selectedAccountId: null,
      totalBalance: 0,
      selectedBalance: 0,
      accountBalances: {},
      visibleTypes: TransactionType.values.toSet(),
    );
  }

  final List<TransactionEntity> transactions;
  final List<TransactionSection> sections;
  final int? selectedAccountId;
  final double totalBalance;
  final double selectedBalance;
  final Map<int, double> accountBalances;
  final Set<TransactionType> visibleTypes;

  TransactionState copyWith({
    List<TransactionEntity>? transactions,
    List<TransactionSection>? sections,
    Object? selectedAccountId = _unset,
    double? totalBalance,
    double? selectedBalance,
    Map<int, double>? accountBalances,
    Set<TransactionType>? visibleTypes,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      sections: sections ?? this.sections,
      selectedAccountId: identical(selectedAccountId, _unset)
          ? this.selectedAccountId
          : selectedAccountId as int?,
      totalBalance: totalBalance ?? this.totalBalance,
      selectedBalance: selectedBalance ?? this.selectedBalance,
      accountBalances: accountBalances ?? this.accountBalances,
      visibleTypes: visibleTypes ?? this.visibleTypes,
    );
  }

  static const Object _unset = Object();
}

class TransactionSection {
  TransactionSection({required this.title, required this.transactions});
  final String title;
  final List<TransactionEntity> transactions;
}
