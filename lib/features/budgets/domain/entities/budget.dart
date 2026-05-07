import 'budget_period.dart';

class BudgetEntity {
  const BudgetEntity({
    required this.id,
    required this.name,
    required this.limitAmount,
    required this.period,
    required this.allCategories,
    required this.categoryIds,
  });

  final int id;
  final String name;
  final double limitAmount;
  final BudgetPeriod period;
  final bool allCategories;
  final List<int> categoryIds;

  BudgetEntity copyWith({
    int? id,
    String? name,
    double? limitAmount,
    BudgetPeriod? period,
    bool? allCategories,
    List<int>? categoryIds,
  }) {
    return BudgetEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      limitAmount: limitAmount ?? this.limitAmount,
      period: period ?? this.period,
      allCategories: allCategories ?? this.allCategories,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }
}
