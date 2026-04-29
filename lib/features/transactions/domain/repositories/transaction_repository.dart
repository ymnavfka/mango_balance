import '../entities/transaction.dart';

abstract class TransactionRepository {
  Stream<List<TransactionEntity>> watchTransactions();

  Future<void> addTransaction(TransactionEntity tx);

  Future<void> updateTransaction(TransactionEntity tx);

  Future<void> deleteTransaction(int id);
}
