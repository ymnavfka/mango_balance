import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit() : super(TransactionState.initial());

  void addTransaction(TransactionEntity transaction) {
    final updatedList = List<TransactionEntity>.from(state.transactions)
      ..add(transaction);

    emit(state.copyWith(transactions: updatedList));
  }
}