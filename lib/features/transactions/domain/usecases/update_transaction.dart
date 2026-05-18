import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class UpdateTransaction {
  UpdateTransaction(this.repository);

  final TransactionRepository repository;

  Future<void> call(TransactionEntity tx) async {
    if (tx.categoryId <= 0) {
      throw Exception('Категория обязательна');
    }

    await repository.updateTransaction(tx);
  }
}
