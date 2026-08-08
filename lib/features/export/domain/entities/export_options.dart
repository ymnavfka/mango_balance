class ExportOptions {
  const ExportOptions({
    required this.profileIds,
    required this.dateFrom,
    required this.dateTo,
  });

  /// Профили, которые нужно включить в бэкап. Пусто — ошибка.
  final List<int> profileIds;

  /// Необязательный диапазон дат для транзакций.
  final DateTime? dateFrom;
  final DateTime? dateTo;
}
