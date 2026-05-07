class ParsedExpense {
  const ParsedExpense({
    required this.date,
    required this.categoryName,
    required this.accountName,
    required this.amount,
    required this.comment,
  });

  final DateTime date;
  final String categoryName;
  final String accountName;
  final double amount;
  final String? comment;
}

class ParsedIncome {
  const ParsedIncome({
    required this.date,
    required this.categoryName,
    required this.accountName,
    required this.amount,
    required this.comment,
  });

  final DateTime date;
  final String categoryName;
  final String accountName;
  final double amount;
  final String? comment;
}

class ParsedTransfer {
  const ParsedTransfer({
    required this.date,
    required this.fromAccountName,
    required this.toAccountName,
    required this.amount,
    required this.comment,
  });

  final DateTime date;
  final String fromAccountName;
  final String toAccountName;
  final double amount;
  final String? comment;
}

class ParsedImport {
  const ParsedImport({
    required this.expenses,
    required this.incomes,
    required this.transfers,
    required this.skippedRows,
  });

  final List<ParsedExpense> expenses;
  final List<ParsedIncome> incomes;
  final List<ParsedTransfer> transfers;
  final int skippedRows;

  int get totalTransactions =>
      expenses.length + incomes.length + transfers.length;
}
