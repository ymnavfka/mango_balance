import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class WatchTransactions {
  WatchTransactions(this.repository);

  final TransactionRepository repository;

  Stream<List<TransactionEntity>> call() {
    return repository.watchTransactions();
  }
}
