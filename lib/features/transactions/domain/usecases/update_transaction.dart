import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransaction {
  UpdateTransaction(this.repository);

  final TransactionRepository repository;

  Future<void> call(TransactionEntity tx) async {
    await repository.updateTransaction(tx);
  }
}
