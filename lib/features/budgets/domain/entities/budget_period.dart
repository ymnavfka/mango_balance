enum BudgetPeriod { week, month, year }

extension BudgetPeriodX on BudgetPeriod {
  String get label {
    switch (this) {
      case BudgetPeriod.week:
        return 'Week';
      case BudgetPeriod.month:
        return 'Month';
      case BudgetPeriod.year:
        return 'Year';
    }
  }

  String get storageKey {
    switch (this) {
      case BudgetPeriod.week:
        return 'week';
      case BudgetPeriod.month:
        return 'month';
      case BudgetPeriod.year:
        return 'year';
    }
  }

  static BudgetPeriod fromStorage(String value) {
    for (final period in BudgetPeriod.values) {
      if (period.storageKey == value) return period;
    }
    return BudgetPeriod.month;
  }
}
