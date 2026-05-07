import '../../../../core/enums/transaction_type.dart';
import '../entities/transaction.dart';

class FilterTransactionsByType {
  List<TransactionEntity> call(
    List<TransactionEntity> transactions,
    Set<TransactionType> visibleTypes,
  ) {
    if (visibleTypes.length == TransactionType.values.length) {
      return transactions;
    }
    return transactions.where((tx) => visibleTypes.contains(tx.type)).toList();
  }
}
