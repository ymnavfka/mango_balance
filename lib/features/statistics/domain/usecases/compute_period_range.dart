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
        final end = start.add(const Duration(days: 1));
        return PeriodRange(
          start: start,
          end: end,
          label: '${start.day} ${_months[start.month - 1]} ${start.year}',
        );
      case PeriodType.week:
        final base = DateTime(anchor.year, anchor.month, anchor.day);
        final start = base.subtract(Duration(days: base.weekday - 1));
        final end = start.add(const Duration(days: 7));
        final lastDay = end.subtract(const Duration(days: 1));
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
        return anchor.add(Duration(days: direction));
      case PeriodType.week:
        return anchor.add(Duration(days: 7 * direction));
      case PeriodType.month:
        return DateTime(anchor.year, anchor.month + direction, anchor.day);
      case PeriodType.year:
        return DateTime(anchor.year + direction, anchor.month, anchor.day);
      case PeriodType.allTime:
        return anchor;
    }
  }
}
