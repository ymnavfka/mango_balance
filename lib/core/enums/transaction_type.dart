enum TransactionType { income, expense, transfer }

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Доход';
      case TransactionType.expense:
        return 'Расход';
      case TransactionType.transfer:
        return 'Перевод';
    }
  }
}
