class ExportOptions {
  const ExportOptions({
    required this.profileId,
    required this.dateFrom,
    required this.dateTo,
  });

  final int profileId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
}
