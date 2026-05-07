import '../entities/transaction.dart';

abstract class TransactionRepository {
  Stream<List<TransactionEntity>> watchTransactions(int profileId);

  Future<void> addTransaction(TransactionEntity tx);

  Future<void> updateTransaction(TransactionEntity tx);

  Future<void> deleteTransaction(int id);
}
