import '../../../../core/enums/transaction_type.dart';
import '../entities/transaction.dart';

class CalculateAccountBalances {
  /// Считает текущий баланс по каждому счёту: изначальный баланс счёта плюс
  /// движения по транзакциям. [initialBalances] задаёт стартовые суммы по id
  /// счёта (счета без транзакций тоже попадут в результат с их балансом).
  Map<int, double> call(
    List<TransactionEntity> transactions, {
    Map<int, double> initialBalances = const {},
  }) {
    final balances = <int, double>{...initialBalances};

    for (final tx in transactions) {
      balances[tx.accountId] = balances[tx.accountId] ?? 0;

      if (tx.type == TransactionType.income) {
        balances[tx.accountId] = balances[tx.accountId]! + tx.amount.value;
      } else if (tx.type == TransactionType.expense) {
        balances[tx.accountId] = balances[tx.accountId]! - tx.amount.value;
      } else {
        balances[tx.accountId] = balances[tx.accountId]! - tx.amount.value;
        if (tx.toAccountId != null) {
          balances[tx.toAccountId!] =
              (balances[tx.toAccountId!] ?? 0) + tx.amount.value;
        }
      }
    }

    return balances;
  }
}
