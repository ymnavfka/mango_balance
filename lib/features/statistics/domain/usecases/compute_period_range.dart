import '../entities/period_range.dart';
import '../entities/period_type.dart';

class ComputePeriodRange {
  static const _months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  PeriodRange call({
    required PeriodType type,
    required DateTime anchor,
    DateTime? earliestTransactionDate,
  }) {
    switch (type) {
      case PeriodType.day:
        final start = DateTime(anchor.year, anchor.month, anchor.day);
        final end = DateTime(anchor.year, anchor.month, anchor.day + 1);
        return PeriodRange(
          start: start,
          end: end,
          label: '${start.day} ${_months[start.month - 1]} ${start.year}',
        );
      case PeriodType.week:
        final base = DateTime(anchor.year, anchor.month, anchor.day);
        final start = DateTime(
          base.year,
          base.month,
          base.day - base.weekday + 1,
        );
        final end = DateTime(start.year, start.month, start.day + 7);
        final lastDay = DateTime(end.year, end.month, end.day - 1);
        return PeriodRange(
          start: start,
          end: end,
          label:
              '${start.day} ${_months[start.month - 1]} – ${lastDay.day} ${_months[lastDay.month - 1]} ${lastDay.year}',
        );
      case PeriodType.month:
        final start = DateTime(anchor.year, anchor.month, 1);
        final end = DateTime(anchor.year, anchor.month + 1, 1);
        return PeriodRange(
          start: start,
          end: end,
          label: '${_months[start.month - 1]} ${start.year}',
        );
      case PeriodType.year:
        final start = DateTime(anchor.year, 1, 1);
        final end = DateTime(anchor.year + 1, 1, 1);
        return PeriodRange(start: start, end: end, label: '${start.year}');
      case PeriodType.allTime:
        final start = earliestTransactionDate != null
            ? DateTime(
                earliestTransactionDate.year,
                earliestTransactionDate.month,
                earliestTransactionDate.day,
              )
            : DateTime(2000, 1, 1);
        final end = DateTime(anchor.year + 1, 1, 1);
        return PeriodRange(start: start, end: end, label: 'За всё время');
    }
  }

  DateTime shiftAnchor({
    required PeriodType type,
    required DateTime anchor,
    required int direction,
  }) {
    switch (type) {
      case PeriodType.day:
        return DateTime(anchor.year, anchor.month, anchor.day + direction);
      case PeriodType.week:
        return DateTime(anchor.year, anchor.month, anchor.day + 7 * direction);
      case PeriodType.month:
        return _clampedDate(anchor.year, anchor.month + direction, anchor.day);
      case PeriodType.year:
        return _clampedDate(anchor.year + direction, anchor.month, anchor.day);
      case PeriodType.allTime:
        return anchor;
    }
  }

  static DateTime _clampedDate(int year, int month, int day) {
    final targetMonth = DateTime(year, month);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    return DateTime(
      targetMonth.year,
      targetMonth.month,
      day > lastDay ? lastDay : day,
    );
  }
}
