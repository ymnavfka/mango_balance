import '../../../../core/database/app_database.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/value_objects/amount.dart';
import '../../domain/value_objects/transaction_date.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this.db);

  final AppDatabase db;

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    return db.watchTransactions().map(
      (list) => list.map(_mapToEntity).toList(),
    );
  }

  @override
  Future<void> addTransaction(TransactionEntity tx) async {
    await db.insertTransaction(
      TransactionsCompanion.insert(
        type: _mapType(tx.type),
        amount: tx.amount.value,
        date: tx.date.value,
      ),
    );
  }

  @override
  Future<void> updateTransaction(TransactionEntity tx) async {
    await db.updateTransaction(
      Transaction(
        id: tx.id,
        type: _mapType(tx.type),
        amount: tx.amount.value,
        date: tx.date.value,
      ),
    );
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await db.deleteTransaction(id);
  }

  TransactionEntity _mapToEntity(Transaction dbTx) {
    return TransactionEntity(
      id: dbTx.id,
      type: dbTx.type == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: Amount(dbTx.amount),
      date: TransactionDate(dbTx.date),
    );
  }

  String _mapType(TransactionType type) {
    return type == TransactionType.income ? 'income' : 'expense';
  }
}
