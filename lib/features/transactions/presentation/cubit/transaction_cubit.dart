import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit() : super(TransactionState.initial());

  int _idCounter = 0;

  void addTransaction(TransactionEntity transaction) {
    final newTransaction = transaction.copyWith(id: _idCounter++);

    final updatedList = List<TransactionEntity>.from(state.transactions)
      ..add(newTransaction);

    emit(state.copyWith(transactions: updatedList));
  }

  void updateTransaction(TransactionEntity updatedTransaction) {
    final updatedList = state.transactions.map((tx) {
      return tx.id == updatedTransaction.id ? updatedTransaction : tx;
    }).toList();

    emit(state.copyWith(transactions: updatedList));
  }

    void deleteTransaction(int id) {
        final updatedList =
            state.transactions.where((tx) => tx.id != id).toList();

        emit(state.copyWith(transactions: updatedList));
    }
}