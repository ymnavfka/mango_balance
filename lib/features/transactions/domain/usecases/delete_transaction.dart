import '../repositories/transaction_repository.dart';

class DeleteTransaction {
  DeleteTransaction(this.repository);

  final TransactionRepository repository;

  Future<void> call(int id) async {
    await repository.deleteTransaction(id);
  }
}
