import 'period_range.dart';

class PeriodBucket {
  PeriodBucket({
    required this.range,
    required this.income,
    required this.expense,
  });

  final PeriodRange range;
  final double income;
  final double expense;

  double get net => income - expense;
}
