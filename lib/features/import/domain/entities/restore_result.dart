class RestoreResult {
  const RestoreResult({
    required this.profileNames,
    required this.importedTransactions,
    required this.createdBudgets,
    required this.createdRecurring,
  });

  final List<String> profileNames;
  final int importedTransactions;
  final int createdBudgets;
  final int createdRecurring;

  int get createdProfiles => profileNames.length;
}
