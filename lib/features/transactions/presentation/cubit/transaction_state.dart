import '../../domain/entities/transaction.dart';

class TransactionState {
  TransactionState({required this.transactions, required this.sections});

  factory TransactionState.initial() {
    return TransactionState(transactions: [], sections: []);
  }
  final List<TransactionEntity> transactions;
  final List<TransactionSection> sections;

  TransactionState copyWith({
    List<TransactionEntity>? transactions,
    List<TransactionSection>? sections,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      sections: sections ?? this.sections,
    );
  }
}

class TransactionSection {
  TransactionSection({required this.title, required this.transactions});
  final String title;
  final List<TransactionEntity> transactions;
}
