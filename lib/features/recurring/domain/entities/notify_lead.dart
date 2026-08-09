/// Единица упреждения оповещения о регулярном платеже: за сколько часов / дней /
/// недель / месяцев до платежа показать напоминание.
enum NotifyLeadUnit { hour, day, week, month }

extension NotifyLeadUnitX on NotifyLeadUnit {
  String get storageKey {
    switch (this) {
      case NotifyLeadUnit.hour:
        return 'hour';
      case NotifyLeadUnit.day:
        return 'day';
      case NotifyLeadUnit.week:
        return 'week';
      case NotifyLeadUnit.month:
        return 'month';
    }
  }

  /// Название в именительном падеже единственного числа — для выпадающего списка.
  String get singularLabel {
    switch (this) {
      case NotifyLeadUnit.hour:
        return 'Час';
      case NotifyLeadUnit.day:
        return 'День';
      case NotifyLeadUnit.week:
        return 'Неделя';
      case NotifyLeadUnit.month:
        return 'Месяц';
    }
  }

  /// Форма единицы, согласованная с числом (русская плюрализация).
  String unitForCount(int count) {
    switch (this) {
      case NotifyLeadUnit.hour:
        return _plural(count, 'час', 'часа', 'часов');
      case NotifyLeadUnit.day:
        return _plural(count, 'день', 'дня', 'дней');
      case NotifyLeadUnit.week:
        return _plural(count, 'неделю', 'недели', 'недель');
      case NotifyLeadUnit.month:
        return _plural(count, 'месяц', 'месяца', 'месяцев');
    }
  }

  static NotifyLeadUnit fromStorage(String value) {
    for (final unit in NotifyLeadUnit.values) {
      if (unit.storageKey == value) return unit;
    }
    return NotifyLeadUnit.day;
  }
}

/// Подпись упреждения: «За 1 день до платежа», «За 3 часа до платежа».
String notifyLeadLabel(NotifyLeadUnit unit, int count) {
  return 'За $count ${unit.unitForCount(count)} до платежа';
}

String _plural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return many;
  if (mod10 == 1) return one;
  if (mod10 >= 2 && mod10 <= 4) return few;
  return many;
}
