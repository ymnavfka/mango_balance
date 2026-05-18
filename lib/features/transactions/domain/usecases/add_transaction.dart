import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class AddTransaction {
  AddTransaction(this.repository);

  final TransactionRepository repository;

  Future<void> call(TransactionEntity tx) async {
    if (tx.amount.value <= 0) {
      throw Exception('Сумма должна быть больше нуля');
    }

    if (tx.categoryId <= 0) {
      throw Exception('Категория обязательна');
    }

    await repository.addTransaction(tx);
  }
}
