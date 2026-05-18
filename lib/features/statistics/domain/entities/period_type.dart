enum PeriodType { day, week, month, year, allTime }

extension PeriodTypeX on PeriodType {
  String get label {
    switch (this) {
      case PeriodType.day:
        return 'День';
      case PeriodType.week:
        return 'Неделя';
      case PeriodType.month:
        return 'Месяц';
      case PeriodType.year:
        return 'Год';
      case PeriodType.allTime:
        return 'За всё время';
    }
  }
}
