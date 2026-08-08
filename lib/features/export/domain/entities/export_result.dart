class ExportResult {
  const ExportResult({
    required this.profileNames,
    required this.transactionsCount,
    required this.savedPath,
  });

  final List<String> profileNames;
  final int transactionsCount;
  final String? savedPath;

  int get profilesCount => profileNames.length;
}
