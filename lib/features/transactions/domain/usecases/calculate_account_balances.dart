import '../../../../core/enums/transaction_type.dart';
import '../entities/transaction.dart';

class CalculateAccountBalances {
  Map<int, double> call(List<TransactionEntity> transactions) {
    final balances = <int, double>{};

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
