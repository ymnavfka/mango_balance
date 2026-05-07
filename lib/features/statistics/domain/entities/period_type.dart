enum PeriodType { day, week, month, year, allTime }

extension PeriodTypeX on PeriodType {
  String get label {
    switch (this) {
      case PeriodType.day:
        return 'Day';
      case PeriodType.week:
        return 'Week';
      case PeriodType.month:
        return 'Month';
      case PeriodType.year:
        return 'Year';
      case PeriodType.allTime:
        return 'All time';
    }
  }
}
