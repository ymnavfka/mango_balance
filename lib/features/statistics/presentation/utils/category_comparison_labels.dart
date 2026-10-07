import '../../domain/entities/period_range.dart';
import '../../domain/entities/period_type.dart';

const _shortMonths = [
  'янв.',
  'февр.',
  'мар.',
  'апр.',
  'мая',
  'июн.',
  'июл.',
  'авг.',
  'сент.',
  'окт.',
  'нояб.',
  'дек.',
];

const _months = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

String categoryPeriodLabel(
  PeriodType type,
  PeriodRange range, {
  bool matchesElapsedDays = false,
  int? elapsedDays,
}) {
  if (matchesElapsedDays && elapsedDays != null) {
    if (type == PeriodType.year) return 'С начала года';
    final lastDay = DateTime(
      range.start.year,
      range.start.month,
      range.start.day + elapsedDays - 1,
    );
    return _dateSpan(range.start, lastDay);
  }

  return switch (type) {
    PeriodType.day => _shortDate(range.start),
    PeriodType.week => _dateSpan(range.start, _previousDay(range.end)),
    PeriodType.month => _months[range.start.month - 1],
    PeriodType.year => '${range.start.year}',
    PeriodType.allTime => 'Вся история',
  };
}

String categoryAverageLabel(
  PeriodType type, {
  bool matchesElapsedDays = false,
}) {
  if (matchesElapsedDays) return 'Среднее за эти дни';
  return switch (type) {
    PeriodType.day => 'Среднее за день',
    PeriodType.week => 'Среднее за неделю',
    PeriodType.month => 'Среднее за месяц',
    PeriodType.year => 'Среднее за год',
    PeriodType.allTime => 'В среднем',
  };
}

String comparisonHistoryLabel(PeriodType type, DateTime start, DateTime end) {
  final lastDay = _previousDay(end);
  if (type == PeriodType.year) {
    return start.year == lastDay.year
        ? '${start.year}'
        : '${start.year} — ${lastDay.year}';
  }
  if (type == PeriodType.month) {
    final first = '${_shortMonths[start.month - 1]} ${start.year}';
    final last = '${_shortMonths[lastDay.month - 1]} ${lastDay.year}';
    return first == last ? first : '$first — $last';
  }
  return _dateSpan(start, lastDay, includeYear: true);
}

String comparisonPeriodCountLabel(PeriodType type, int count) {
  final forms = switch (type) {
    PeriodType.day => ['полный день', 'полных дня', 'полных дней'],
    PeriodType.week => ['полная неделя', 'полные недели', 'полных недель'],
    PeriodType.month => ['полный месяц', 'полных месяца', 'полных месяцев'],
    PeriodType.year => ['полный год', 'полных года', 'полных лет'],
    PeriodType.allTime => [
      'полный период',
      'полных периода',
      'полных периодов',
    ],
  };
  final lastTwo = count % 100;
  final last = count % 10;
  final index = lastTwo >= 11 && lastTwo <= 14
      ? 2
      : last == 1
      ? 0
      : last >= 2 && last <= 4
      ? 1
      : 2;
  return '$count ${forms[index]}';
}

String _dateSpan(DateTime start, DateTime end, {bool includeYear = false}) {
  if (start.year == end.year && start.month == end.month) {
    final days = start.day == end.day
        ? '${start.day}'
        : '${start.day}–${end.day}';
    return '$days ${_shortMonths[start.month - 1]}'
        '${includeYear ? ' ${end.year}' : ''}';
  }
  if (start.year == end.year) {
    return '${_shortDate(start)} — ${_shortDate(end)}'
        '${includeYear ? ' ${end.year}' : ''}';
  }
  return '${_shortDate(start)} ${start.year} — '
      '${_shortDate(end)} ${end.year}';
}

String _shortDate(DateTime date) =>
    '${date.day} ${_shortMonths[date.month - 1]}';

DateTime _previousDay(DateTime date) =>
    DateTime(date.year, date.month, date.day - 1);
