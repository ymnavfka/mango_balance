import 'budget.dart';

enum BudgetStatus { under, warning, over }

class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.periodStart,
    required this.periodEnd,
    required this.daysRemaining,
    required this.categoryNames,
  });

  final BudgetEntity budget;
  final double spent;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int daysRemaining;
  final List<String> categoryNames;

  double get limit => budget.limitAmount;
  double get remaining => limit - spent;
  double get fillRatio => limit <= 0 ? 0 : spent / limit;

  BudgetStatus get status {
    if (spent >= limit) return BudgetStatus.over;
    if (fillRatio >= 0.8) return BudgetStatus.warning;
    return BudgetStatus.under;
  }
}
