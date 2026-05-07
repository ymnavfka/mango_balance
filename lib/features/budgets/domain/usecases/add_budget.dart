import '../entities/budget.dart';
import '../repositories/budget_repository.dart';

class AddBudget {
  AddBudget(this.repository);

  final BudgetRepository repository;

  Future<int> call(BudgetEntity budget) {
    return repository.addBudget(budget);
  }
}
