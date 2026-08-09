import 'entities/notify_lead.dart';
import 'entities/recurring_payment.dart';

/// Момент показа напоминания: за [RecurringPaymentEntity.notifyValue]
/// [RecurringPaymentEntity.notifyUnit] до [RecurringPaymentEntity.nextRunDate].
///
/// Для дней/недель/месяцев напоминание ставится на 12:00 вычисленного дня
/// (у платежа нет времени суток), для часов — точное смещение. Возвращает null,
/// если оповещение отключено или упреждение некорректно.
DateTime? reminderTimeFor(RecurringPaymentEntity payment) {
  final value = payment.notifyValue;
  final unit = payment.notifyUnit;
  if (value == null || unit == null || value <= 0) return null;

  final due = payment.nextRunDate;
  switch (unit) {
    case NotifyLeadUnit.hour:
      return due.subtract(Duration(hours: value));
    case NotifyLeadUnit.day:
      return _atNoon(due.subtract(Duration(days: value)));
    case NotifyLeadUnit.week:
      return _atNoon(due.subtract(Duration(days: 7 * value)));
    case NotifyLeadUnit.month:
      return _atNoon(_subtractMonths(due, value));
  }
}

DateTime _atNoon(DateTime d) => DateTime(d.year, d.month, d.day, 12);

DateTime _subtractMonths(DateTime date, int months) {
  final target = DateTime(date.year, date.month - months, 1);
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  final day = date.day < lastDay ? date.day : lastDay;
  return DateTime(target.year, target.month, day);
}
