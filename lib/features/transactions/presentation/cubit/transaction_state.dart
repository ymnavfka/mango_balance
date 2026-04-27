import '../../domain/entities/transaction.dart';

class TransactionState {

  TransactionState({required this.transactions});

  factory TransactionState.initial() {
    return TransactionState(transactions: []);
  }
  final List<TransactionEntity> transactions;

  TransactionState copyWith({List<TransactionEntity>? transactions}) {
    return TransactionState(transactions: transactions ?? this.transactions);
  }
}
