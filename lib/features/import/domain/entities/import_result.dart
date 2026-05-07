class ImportResult {
  const ImportResult({
    required this.profileId,
    required this.profileName,
    required this.importedTransactions,
    required this.createdCategories,
    required this.createdAccounts,
    required this.skippedRows,
  });

  final int profileId;
  final String profileName;
  final int importedTransactions;
  final int createdCategories;
  final int createdAccounts;
  final int skippedRows;
}
