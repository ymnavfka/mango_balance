/// Единица периода повторения регулярного платежа. Вместе с числом повторений
/// (`intervalCount`) задаёт произвольный интервал: «каждые N дней/недель/...».
enum RecurringInterval { day, week, month, year }

extension RecurringIntervalX on RecurringInterval {
  String get storageKey {
    switch (this) {
      case RecurringInterval.day:
        return 'day';
      case RecurringInterval.week:
        return 'week';
      case RecurringInterval.month:
        return 'month';
      case RecurringInterval.year:
        return 'year';
    }
  }

  /// Название единицы в именительном падеже единственного числа — для выпадающего
  /// списка («День», «Неделя», «Месяц», «Год»).
  String get singularLabel {
    switch (this) {
      case RecurringInterval.day:
        return 'День';
      case RecurringInterval.week:
        return 'Неделя';
      case RecurringInterval.month:
        return 'Месяц';
      case RecurringInterval.year:
        return 'Год';
    }
  }

  /// Форма единицы, согласованная с числом `count` (русская плюрализация):
  /// 2 → «дня», 5 → «дней» и т.д.
  String unitForCount(int count) {
    switch (this) {
      case RecurringInterval.day:
        return _plural(count, 'день', 'дня', 'дней');
      case RecurringInterval.week:
        return _plural(count, 'неделя', 'недели', 'недель');
      case RecurringInterval.month:
        return _plural(count, 'месяц', 'месяца', 'месяцев');
      case RecurringInterval.year:
        return _plural(count, 'год', 'года', 'лет');
    }
  }

  static RecurringInterval fromStorage(String value) {
    for (final unit in RecurringInterval.values) {
      if (unit.storageKey == value) return unit;
    }
    return RecurringInterval.month;
  }
}

/// Человекочитаемая подпись периода: «Каждый день», «Каждые 2 недели» и т.п.
String recurrenceLabel(RecurringInterval unit, int count) {
  if (count <= 1) {
    switch (unit) {
      case RecurringInterval.day:
        return 'Каждый день';
      case RecurringInterval.week:
        return 'Каждую неделю';
      case RecurringInterval.month:
        return 'Каждый месяц';
      case RecurringInterval.year:
        return 'Каждый год';
    }
  }
  return 'Каждые $count ${unit.unitForCount(count)}';
}

/// Следующая дата срабатывания после [from] через [count] единиц [unit].
/// Для месяцев и лет день месяца подрезается до последнего дня (например,
/// 31 января + 1 месяц → 28/29 февраля).
DateTime nextOccurrence(DateTime from, RecurringInterval unit, int count) {
  switch (unit) {
    case RecurringInterval.day:
      return from.add(Duration(days: count));
    case RecurringInterval.week:
      return from.add(Duration(days: 7 * count));
    case RecurringInterval.month:
      return _addMonths(from, count);
    case RecurringInterval.year:
      return _addMonths(from, 12 * count);
  }
}

DateTime _addMonths(DateTime date, int months) {
  final total = date.month - 1 + months;
  final year = date.year + (total ~/ 12);
  final month = (total % 12) + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day < lastDay ? date.day : lastDay;
  return DateTime(year, month, day, date.hour, date.minute);
}

String _plural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return many;
  if (mod10 == 1) return one;
  if (mod10 >= 2 && mod10 <= 4) return few;
  return many;
}
