/// Полный бэкап приложения, разобранный из XLSX. Все связи хранятся по исходным
/// id (sourceId) из файла и переотображаются на новые id при восстановлении.
class BackupProfile {
  const BackupProfile({
    required this.sourceId,
    required this.name,
    required this.isActive,
  });

  final int sourceId;
  final String name;
  final bool isActive;
}

class BackupAccount {
  const BackupAccount({
    required this.sourceId,
    required this.profileSourceId,
    required this.name,
    required this.initialBalance,
    required this.isFallback,
    this.isArchived = false,
  });

  final int sourceId;
  final int profileSourceId;
  final String name;
  final double initialBalance;
  final bool isFallback;
  final bool isArchived;
}

class BackupCategory {
  const BackupCategory({
    required this.sourceId,
    required this.profileSourceId,
    required this.name,
    required this.type,
    required this.isFallback,
    this.isArchived = false,
  });

  final int sourceId;
  final int profileSourceId;
  final String name;
  final String type;
  final bool isFallback;
  final bool isArchived;
}

class BackupTransaction {
  const BackupTransaction({
    required this.profileSourceId,
    required this.type,
    required this.amount,
    required this.date,
    required this.categorySourceId,
    required this.accountSourceId,
    required this.toAccountSourceId,
    required this.comment,
  });

  final int profileSourceId;
  final String type; // income | expense | transfer
  final double amount;
  final DateTime date;
  final int? categorySourceId; // null для переводов
  final int? accountSourceId;
  final int? toAccountSourceId; // только для переводов
  final String? comment;
}

class BackupBudget {
  const BackupBudget({
    required this.sourceId,
    required this.profileSourceId,
    required this.name,
    required this.limitAmount,
    required this.periodType,
    required this.allCategories,
  });

  final int sourceId;
  final int profileSourceId;
  final String name;
  final double limitAmount;
  final String periodType;
  final bool allCategories;
}

class BackupBudgetCategory {
  const BackupBudgetCategory({
    required this.budgetSourceId,
    required this.categorySourceId,
  });

  final int budgetSourceId;
  final int categorySourceId;
}

class BackupRecurring {
  const BackupRecurring({
    required this.profileSourceId,
    required this.name,
    required this.type,
    required this.amount,
    required this.categorySourceId,
    required this.accountSourceId,
    required this.intervalUnit,
    required this.intervalCount,
    required this.startDate,
    required this.nextRunDate,
    required this.isActive,
  });

  final int profileSourceId;
  final String name;
  final String type;
  final double amount;
  final int? categorySourceId;
  final int? accountSourceId;
  final String intervalUnit;
  final int intervalCount;
  final DateTime startDate;
  final DateTime nextRunDate;
  final bool isActive;
}

class BackupData {
  const BackupData({
    required this.profiles,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.budgetCategories,
    required this.recurring,
  });

  final List<BackupProfile> profiles;
  final List<BackupAccount> accounts;
  final List<BackupCategory> categories;
  final List<BackupTransaction> transactions;
  final List<BackupBudget> budgets;
  final List<BackupBudgetCategory> budgetCategories;
  final List<BackupRecurring> recurring;

  int get profilesCount => profiles.length;
  int get transactionsCount => transactions.length;
  int get budgetsCount => budgets.length;
  int get recurringCount => recurring.length;
}
