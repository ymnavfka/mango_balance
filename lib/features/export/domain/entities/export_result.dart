class ExportResult {
  const ExportResult({
    required this.profileName,
    required this.exportedTransactions,
    required this.savedPath,
  });

  final String profileName;
  final int exportedTransactions;
  final String? savedPath;
}
