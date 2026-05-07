class PeriodRange {
  PeriodRange({required this.start, required this.end, required this.label});

  final DateTime start;
  final DateTime end;
  final String label;

  bool contains(DateTime date) {
    return !date.isBefore(start) && date.isBefore(end);
  }
}
