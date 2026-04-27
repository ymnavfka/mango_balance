import '../../domain/entities/transaction.dart';

class TransactionState {
  final List<TransactionEntity> transactions;

  TransactionState({required this.transactions});

  factory TransactionState.initial() {
    return TransactionState(transactions: []);
  }

  TransactionState copyWith({
    List<TransactionEntity>? transactions,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
    );
  }
}