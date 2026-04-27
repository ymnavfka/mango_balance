import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_state.dart';
import '../../../../core/enums/transaction_type.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final AppDatabase db;

  TransactionCubit(this.db) : super(TransactionState.initial()) {
    _init();
  }

  void _init() {
    db.watchTransactions().listen((data) {
      final list = data.map(_mapToEntity).toList();
      emit(state.copyWith(transactions: list));
    });
  }

  TransactionEntity _mapToEntity(Transaction dbTx) {
    return TransactionEntity(
      id: dbTx.id,
      type: dbTx.type == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: dbTx.amount,
      date: dbTx.date,
    );
  }

  String _mapType(TransactionType type) {
    return type == TransactionType.income ? 'income' : 'expense';
  }

  // CREATE
  Future<void> addTransaction(TransactionEntity tx) async {
    await db.insertTransaction(
      TransactionsCompanion.insert(
        type: _mapType(tx.type),
        amount: tx.amount,
        date: tx.date,
      ),
    );
  }

  // UPDATE
  Future<void> updateTransaction(TransactionEntity tx) async {
    await db.updateTransaction(
      Transaction(
        id: tx.id,
        type: _mapType(tx.type),
        amount: tx.amount,
        date: tx.date,
      ),
    );
  }

  // DELETE
  Future<void> deleteTransaction(int id) async {
    await db.deleteTransaction(id);
  }

  // RESTORE
  Future<void> restoreTransaction(TransactionEntity tx, int index) async {
    await addTransaction(tx);
  }
}