import '../entities/transaction.dart';

class FilterTransactionsByAccount {
  List<TransactionEntity> call(
    List<TransactionEntity> transactions,
    int? selectedAccountId,
  ) {
    if (selectedAccountId == null) {
      return transactions;
    }

    return transactions.where((tx) {
      return tx.accountId == selectedAccountId ||
          tx.toAccountId == selectedAccountId;
    }).toList();
  }
}
