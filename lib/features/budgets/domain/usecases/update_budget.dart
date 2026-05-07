import '../entities/budget.dart';
import '../repositories/budget_repository.dart';

class UpdateBudget {
  UpdateBudget(this.repository);

  final BudgetRepository repository;

  Future<void> call(BudgetEntity budget) {
    return repository.updateBudget(budget);
  }
}
